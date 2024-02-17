import 'dart:collection';
import 'dart:math' as math;

import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/models/user_video.dart';
import 'package:letsspeak/target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:system_settings/system_settings.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../data/models/transcript.dart';
import '../../di/service_locator.dart';
import '../highlight_text.dart';
import '../thumbs_animation.dart';
import '../home/controller.dart';

final Map<String, String> statuses = HashMap()
  ..addAll({
    'Private': 'Private',
    'Public': 'Public',
  });

/// Homepage
class YoutubePlayerPage extends StatefulWidget {
  final int userVideoId;
  final String youtubeVideoId;
  final UserDataResponse userData;

  const YoutubePlayerPage({
    Key? key,
    required this.userData,
    required this.userVideoId,
    required this.youtubeVideoId,
  }) : super(key: key);

  @override
  State createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  final homeController = getIt<HomeController>();
  final prefs = getIt<SharedPreferences>();

  late YoutubePlayerController _controller;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  bool _isPlaying = false;
  bool _isPlayerReady = false;
  bool userVideoLoaded = false;
  late UserVideo userVideo;

  List<String> translatedTranscripts = [];

  late int pinIndex = -1;
  int curPlayerPosition = 0;
  int curPlayingIndex = 0;

  final SpeechToText _speechToText = SpeechToText();

  int curRecognizingIndex = -1;

  bool updatingVideo = false;
  bool videoHasChanges = false;
  bool showToolbox = false;

  GlobalKey repeatButtonKey = GlobalKey();
  GlobalKey microphoneButtonKey = GlobalKey();
  late TutorialCoachMark tutorial;

  @override
  void initState() {
    super.initState();
    _speechToText.initialize(onStatus: (String status) {
      setState(() {});
    }).then((value) {
      _speechToText.locales().then((List<LocaleName> locales) {
        if (kDebugMode) {
          print(
              "Available locales: ${locales.map((e) => e.localeId + e.name)}");
        }
      });
    });

    final shouldShowTutorial = prefs.getBool('showTutorial') ?? true;

    _controller = YoutubePlayerController(
      initialVideoId: widget.youtubeVideoId,
      flags: YoutubePlayerFlags(
        mute: false,
        autoPlay: !shouldShowTutorial,
        disableDragSeek: true,
        loop: true,
        isLive: false,
        forceHD: false,
        enableCaption: false,
        hideControls: true,
      ),
    )..addListener(listener);

    homeController.getUserVideosApi(widget.userVideoId).then((res) async {
      userVideo = res;
      setState(() {
        userVideoLoaded = true;
      });

      if (shouldShowTutorial) {
        _showTutorial();
      }

      final videoId = userVideo.videoId;
      String lang = widget.userData.firstLanguage ?? 'vi';
      final response = await homeController.getTranslatedTranscriptsApi(videoId, lang);
      setState(() {
        translatedTranscripts.clear();
        if (response.data.isNotEmpty) {
          translatedTranscripts.addAll(response.data[0].transcript);
        }
      });
    });
  }

  void _askToSwitchLanguage() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(AppLocalizations.of(context)!.switch_lang_message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop();
                SystemSettings.locale();
              },
            ),
          ],
        );
      },
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(TargetFocus(
        identify: "Target 1",
        keyTarget: repeatButtonKey,
        contents: [
          TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.tap_to_repeat,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                ],
              ))
        ]));
    targets.add(TargetFocus(
        identify: "Target 2",
        keyTarget: microphoneButtonKey,
        contents: [
          TargetContent(
              align: ContentAlign.top,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context)!.tap_to_speak,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0),
                  ),
                ],
              ))
        ]));
    return targets;
  }

  void _showTutorial() {
    tutorial = TutorialCoachMark(
        targets: _createTargets(),
        colorShadow: Colors.red,
        // alignSkip: Alignment.bottomRight,
        textSkip: AppLocalizations.of(context)!.skip,
        // paddingFocus: 10,
        // focusAnimationDuration: Duration(milliseconds: 500),
        // pulseAnimationDuration: Duration(milliseconds: 500),
        // pulseVariation: Tween(begin: 1.0, end: 0.99),
        onFinish: () async {
          if (kDebugMode) {
            print("finish");
          }
          await prefs.setBool('showTutorial', false);
        },
        onClickTargetWithTapPosition: (target, tapDetails) {
          if (kDebugMode) {
            print("target: $target");
            print(
                "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
          }
        },
        onClickTarget: (target) {
          if (kDebugMode) {
            print(target);
          }
        },
        onSkip: () {
          if (kDebugMode) {
            print("skip");
          }
          return true;
        })
      ..show(context: context);
  }

  void _syncChanges() {
    if (userVideoLoaded) {
      updatingVideo = true;
      homeController.updateVideo(userVideo.video).then((res) {
        videoHasChanges = false;
        setState(() {
          updatingVideo = false;
        });
      }, onError: (err) {
        setState(() {
          updatingVideo = false;
        });
      });
    }
  }

  Future<void> _syncRecognizedWords() async {
    await homeController.updateUserVideosApi(userVideo);
  }

  void _setStart(Transcript transcript) {
    transcript.start = (_controller.value.position.inMilliseconds / 1000);
    setState(() {
      videoHasChanges = true;
    });
  }

  void _moveStartBackward(Transcript transcript) {
    transcript.start = transcript.start - 0.1;
    transcript.duration = transcript.duration + 0.1;
    _controller
        .seekTo(Duration(milliseconds: (transcript.start * 1000).toInt()));
    setState(() {
      videoHasChanges = true;
    });
  }

  void _moveStartForward(Transcript transcript) {
    setState(() {
      transcript.start = transcript.start + 0.1;
      transcript.duration = transcript.duration - 0.1;
      videoHasChanges = true;
    });
    _controller
        .seekTo(Duration(milliseconds: (transcript.start * 1000).toInt()));
  }

  void _moveEndBackward(Transcript transcript) {
    setState(() {
      transcript.duration = transcript.duration - 0.1;
      videoHasChanges = true;
    });
  }

  void _moveEndForward(Transcript transcript) {
    setState(() {
      transcript.duration = transcript.duration + 0.1;
      videoHasChanges = true;
    });
  }

  void _setEnd(Transcript transcript) {
    setState(() {
      final dur = _controller.value.position.inMilliseconds - transcript.start * 1000;
      transcript.duration = dur / 1000;
      videoHasChanges = true;
    });
  }

  void _change(int index, String value) {
    Transcript transcript = userVideo.video.transcript[index];
    transcript.text = value;
    setState(() {
      videoHasChanges = true;
    });
  }

  void _split(int index, TextEditingController controller) {
    int baseOffset = controller.selection.baseOffset;
    if (baseOffset >= 0) {
      String text = controller.text;
      String line1 = text.substring(0, baseOffset).trim();
      String line2 = text.substring(baseOffset).trim();

      Transcript currentTranscript = userVideo.video.transcript[index];
      currentTranscript.text = line1;
      currentTranscript.controller?.text = line1;

      Transcript newTranscript = Transcript(
        text: line2,
        start: currentTranscript.start,
        tokens: List.empty(),
        duration: currentTranscript.duration,
        translatedText: null,
        controller: TextEditingController(text: line2)
      );

      _setEnd(currentTranscript);
      _setStart(newTranscript);

      userVideo.video.transcript.insert(index + 1, newTranscript);
      userVideo.video.countTranscript = userVideo.video.transcript.length;


      setState(() {
        videoHasChanges = true;
      });
    } else {

      Transcript currentTranscript = userVideo.video.transcript[index];
      Transcript newTranscript = Transcript(
        text: "",
        start: currentTranscript.start + currentTranscript.duration,
        tokens: List.empty(),
        duration: currentTranscript.duration,
        translatedText: null,
        controller: TextEditingController()
      );

      userVideo.video.transcript.insert(index + 1, newTranscript);
      userVideo.video.countTranscript = userVideo.video.transcript.length;

      setState(() {
        videoHasChanges = true;
      });
    }
  }

  void _join(int index) {
    Transcript transcript1 = userVideo.video.transcript[index - 1];
    Transcript transcript2 = userVideo.video.transcript[index];

    transcript1.text = "${transcript1.text} ${transcript2.text}";
    transcript1.duration = transcript2.duration;
    transcript1.controller?.text = transcript1.text;
    _setEnd(transcript1);

    userVideo.video.transcript.removeAt(index);
    userVideo.video.countTranscript = userVideo.video.transcript.length;

    setState(() {
      videoHasChanges = true;
    });
  }

  void _drop(int index) {
    userVideo.video.transcript.removeAt(index);
    userVideo.video.countTranscript = userVideo.video.transcript.length;

    setState(() {
      videoHasChanges = true;
    });
  }

  /// Each time to start a speech recognition session
  void _startListening() {
    _speechToText.listen(
      localeId: 'en-US',
      pauseFor: isIOS() ? const Duration(seconds: 2) : null,
      onResult: _onSpeechResult,
      cancelOnError: true,
    );
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that each platform enforces
  /// and the SpeechToText plugin supports setting timeouts on the
  /// listen method.
  void _stopListening() {
    _speechToText.stop();
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      final index = curRecognizingIndex.toString();
      userVideo.recognizedWords[index] = result.recognizedWords;
      userVideo.countPractisedSentences = userVideo.recognizedWords.length;
    });

    if (result.finalResult) {
      _syncRecognizedWords();
    }
  }

  void listener() {
    if (userVideoLoaded &&
        curPlayerPosition != _controller.value.position.inMilliseconds) {
      curPlayerPosition = _controller.value.position.inMilliseconds;

      if (_isPlayerReady && mounted && pinIndex != -1) {
        final transcript = userVideo.video.transcript[pinIndex];
        final start = (transcript.start * 1000).toInt();
        final end = ((transcript.start + transcript.duration) * 1000).toInt();
        if (curPlayerPosition < start || curPlayerPosition > end) {
          _controller.seekTo(
              Duration(milliseconds: (transcript.start * 1000).toInt()));
        }
      }

      // TODO: improve lookup algorithm
      int index = userVideo.video.transcript.indexWhere((e) {
        num start = e.start * 1000;
        num end = (e.start + e.duration) * 1000;
        return start < curPlayerPosition && curPlayerPosition < end;
      });

      if (index != -1 && curPlayingIndex != index) {
        itemScrollController.scrollTo(
          index: index,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOutCubic,
        );
        setState(() {
          curPlayingIndex = index;
        });
      }
    }

    if (_isPlaying != _controller.value.isPlaying) {
      _isPlaying = _controller.value.isPlaying;
      setState(() {});
    }
  }

  void setPinIndex(int index) {
    setState(() {
      pinIndex = index;
    });
    if (pinIndex == -1) {
      _controller.pause();
    } else {
      final dur = (userVideo.video.transcript[pinIndex].start * 1000).toInt();
      _controller.seekTo(Duration(milliseconds: dur));
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // The player forces portraitUp after exiting fullscreen. This overrides the behaviour.
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blueAccent,
        topActions: const <Widget>[],
        onReady: () {
          setState(() {
            _isPlayerReady = true;
          });
        },
      ),
      builder: (context, player) => Scaffold(
        appBar: AppBar(
          title: Text(
            userVideoLoaded ? userVideo.video.title : '',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            PopupMenuButton(itemBuilder: (context) {
              List<PopupMenuItem> menus = [];

              if (widget.userData.isAdmin) {
                menus.add(PopupMenuItem<String>(
                  value: "edit_transcript",
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              showToolbox = !showToolbox;
                            });
                          },
                          icon: Icon(showToolbox ? Icons.edit_off : Icons.edit),
                          label: Text(AppLocalizations.of(context)!.edit_transcript),
                        ),
                      )
                    ],
                  ),
                ));
              }

              menus.add(PopupMenuItem<String>(
                value: "view_on_youtube",
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          launchUrlString(AppLocalizations.of(context)!.youtube(widget.youtubeVideoId));
                        },
                        icon: const Icon(Icons.output),
                        label: Text(AppLocalizations.of(context)!.view_on_youtube),
                      ),
                    )
                  ],
                ),
              ));

              return menus;
            }),
          ],
        ),
        body: Column(
          children: [
            player,
            _space,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Visibility(
                  visible: widget.userData.isAdmin,
                  child: DropdownButton<String>(
                    value: userVideoLoaded ? userVideo.video.visibility : 'Private',
                    items: statuses
                        .map<String, DropdownMenuItem<String>>((String key, String value) {
                      return MapEntry(
                        key,
                        DropdownMenuItem<String>(
                          value: key,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Icon(key == 'Private' ? Icons.lock : Icons.public, size: 14),
                                  alignment: PlaceholderAlignment.middle,
                                ),
                                TextSpan(text: value),
                              ],
                            ),
                            style: (const TextStyle(fontSize: 14)),
                          ),
                        ),
                      );
                    })
                        .values
                        .toList(),
                    onChanged: (String? newStatus) {
                      setState(() {
                        userVideo.video.visibility = newStatus!;
                        _syncChanges();
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  onPressed: _isPlayerReady
                      ? () {
                          _controller.seekTo(_controller.value.position -
                              const Duration(seconds: 5));
                          setPinIndex(-1);
                        }
                      : null,
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: _isPlayerReady
                      ? () {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward),
                  onPressed: _isPlayerReady
                      ? () {
                          _controller.seekTo(_controller.value.position +
                              const Duration(seconds: 5));
                          setPinIndex(-1);
                        }
                      : null,
                ),
                Visibility(
                  visible: showToolbox,
                  child: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed:
                        updatingVideo || !videoHasChanges ? null : _syncChanges,
                  ),
                )
              ],
            ),
            _space,
            Expanded(
              child: (
                userVideoLoaded ?
                buildTranscript(context) :
                const Center(child: CircularProgressIndicator())
              ),
            ),
          ],
        ),
      ),
    );
  }

  HighlightedWord get _highlightedWord => HighlightedWord(
    textStyle: const TextStyle(
      color: Colors.green,
      fontWeight: FontWeight.bold,
      fontSize: 16,
      inherit: false,
    ),
  );

  Widget buildTranscript(BuildContext context) {

    if (userVideo.video.status == Status.PUBLISHED) {
      return ScrollablePositionedList.builder(
        itemCount: userVideo.video.transcript.length,
        itemBuilder: (BuildContext context, int index) {
          final Transcript transcript =
          userVideo.video.transcript[index];
          final String translatedText =
          translatedTranscripts.length > index
              ? translatedTranscripts[index]
              : '';
          final words = {
            for (String word in transcript.text
                .replaceAll(RegExp(r"[^'\s\w]"), '')
                .replaceAll(RegExp(r"^'"), '')
                .replaceAll(RegExp(r"'$"), '')
                .replaceAll(RegExp(r"\s'"), ' ')
                .replaceAll(RegExp(r"'\s"), ' ')
                .split(' '))
              word: _highlightedWord
          };
          final String recognizedWords =
              userVideo.recognizedWords[index.toString()] ?? '';
          final TextHighlight textHighlight = TextHighlight(
            text: recognizedWords,
            words: words,
            textStyle: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.justify,
            binding: HighlightBinding.all,
          );

          bool isThumbsUp = textHighlight.isThumbUp();
          bool isFirstItem = index == 0;

          TextEditingController textController = transcript.controller!;
          return Slidable(
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              extentRatio: 0.2,
              children: [
                SlidableAction(
                  onPressed: (BuildContext context) {
                    _drop(index);
                  },
                  icon: Icons.clear,
                ),
              ],
            ),
            child: Card(
              child: GestureDetector(
                onDoubleTap: () {
                  setPinIndex(-1);
                  final dur = (transcript.start * 1000).toInt();
                  _controller.seekTo(Duration(milliseconds: dur));
                },
                child: Column(
                  children: [
                    Visibility(
                      visible: showToolbox,
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: !isFirstItem,
                            child: IconButton(
                              icon: const Icon(Icons.move_up),
                              onPressed: () {
                                _join(index);
                              },
                            ),
                          ),
                          Transform.rotate(
                            angle: -math.pi / 2,
                            child: IconButton(
                              icon: const Icon(Icons.vertical_align_top),
                              onPressed: () {
                                _setStart(transcript);
                              },
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${transcript.start.toStringAsFixed(2)} - ${transcript.end().toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Transform.rotate(
                            angle: math.pi / 2,
                            child: IconButton(
                              icon: const Icon(Icons.vertical_align_top),
                              onPressed: () {
                                _setEnd(transcript);
                              },
                            ),
                          ),
                          Transform.rotate(
                            angle: math.pi,
                            child: IconButton(
                              icon: const Icon(Icons.move_up),
                              onPressed: () {
                                _split(index, textController);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.only(right: 8, left: 8),
                      isThreeLine: true,
                      title: showToolbox ?
                      TextField(
                        controller: textController,
                        keyboardType: TextInputType.text,
                        maxLines: null,
                        style: TextStyle(
                            fontWeight: curPlayingIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal
                        ),
                        onSubmitted: (value) {
                          _change(index, value);
                        },
                      ) :
                      Text(
                        transcript.text,
                        style: TextStyle(
                          fontWeight:
                          curPlayingIndex == index
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(translatedText),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              setPinIndex(-1);
                              final dur =
                              (transcript.start * 1000).toInt();
                              _controller.seekTo(
                                  Duration(milliseconds: dur));
                            },
                            icon: const Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                            ),
                          ),
                          pinIndex == index
                              ? IconButton(
                            icon: const Icon(
                              Icons.repeat_one_on_outlined,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              _controller.pause();
                              setPinIndex(-1);
                            },
                          )
                              : IconButton(
                            key: index == 0
                                ? repeatButtonKey
                                : null,
                            onPressed: () {
                              setPinIndex(index);
                            },
                            icon: const Icon(
                              Icons.repeat_outlined,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      contentPadding:
                      const EdgeInsets.only(right: 8, left: 8),
                      title: recognizedWords.isNotEmpty
                          ? textHighlight
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: userVideo.recognizedWords
                                .containsKey(
                                index.toString()) ??
                                false,
                            child: IconButton(
                              onPressed: null,
                              icon: ThumbsAnimation(
                                  isThumbsUp: isThumbsUp),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              curRecognizingIndex == index &&
                                  _speechToText.isListening
                                  ? Icons.mic
                                  : Icons.mic_off,
                              color: curRecognizingIndex == index &&
                                  _speechToText.isListening
                                  ? Colors.green
                                  : Colors.black,
                              size: 32,
                            ),
                            onPressed: () {
                              setPinIndex(-1);

                              curRecognizingIndex = index;

                              // If not yet listening for speech start, otherwise stop
                              if (_speechToText.isNotListening) {
                                _startListening();
                              } else {
                                _stopListening();
                              }
                            },
                            key: index == 0
                                ? microphoneButtonKey
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
      );
    }

    return Center(child: Text(AppLocalizations.of(context)!.editing_transcript));
  }

  Widget get _space => const SizedBox(height: 10);
}
