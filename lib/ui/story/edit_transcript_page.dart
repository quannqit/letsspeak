import 'dart:collection';
import 'dart:math' as math;

import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/models/video.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../data/models/transcript.dart';
import '../../di/service_locator.dart';
import '../home/controller.dart';

final Map<String, String> statuses = HashMap()
  ..addAll({
    'Private': 'Private',
    'Public': 'Public',
  });

/// Homepage
class EditTranscriptPage extends StatefulWidget {

  final String youtubeVideoId;
  final int videoId;
  final UserDataResponse userData;

  const EditTranscriptPage({
    Key? key,
    required this.youtubeVideoId,
    required this.userData,
    required this.videoId,
  }) : super(key: key);

  @override
  State createState() => _EditTranscriptPageState();
}

class _EditTranscriptPageState extends State<EditTranscriptPage> {
  final homeController = getIt<HomeController>();
  final prefs = getIt<SharedPreferences>();

  late YoutubePlayerController _controller;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  bool _isPlaying = false;
  bool _isPlayerReady = false;
  bool userVideoLoaded = false;
  late Video video;

  List<String> translatedTranscripts = [];

  late int pinIndex = -1;
  int curPlayerPosition = 0;
  int curPlayingIndex = 0;

  int curRecognizingIndex = -1;

  bool updatingVideo = false;
  bool videoHasChanges = false;

  GlobalKey repeatButtonKey = GlobalKey();
  GlobalKey microphoneButtonKey = GlobalKey();
  late TutorialCoachMark tutorial;

  @override
  void initState() {
    super.initState();

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

    final videoId = widget.videoId;

    homeController.getVideo(videoId).then((res) async {
      video = res;
      setState(() {
        userVideoLoaded = true;
      });
    });

  }

  Future<void> _syncChanges() async {
    if (userVideoLoaded) {
      updatingVideo = true;
      await homeController.updateVideo(video);
      setState(() {
        updatingVideo = false;
        videoHasChanges = false;
      });
    }
  }

  void _setStart(Transcript transcript) {
    transcript.start = ((_controller.value.position.inMilliseconds + 10)/ 1000);
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
    Transcript transcript = video.transcript[index];
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

      Transcript currentTranscript = video.transcript[index];
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

      video.transcript.insert(index + 1, newTranscript);
      video.countTranscript = video.transcript.length;


      setState(() {
        videoHasChanges = true;
      });
    } else {

      Transcript currentTranscript = video.transcript[index];
      Transcript newTranscript = Transcript(
        text: "",
        start: currentTranscript.start + currentTranscript.duration,
        tokens: List.empty(),
        duration: currentTranscript.duration,
        translatedText: null,
        controller: TextEditingController()
      );

      video.transcript.insert(index + 1, newTranscript);
      video.countTranscript = video.transcript.length;

      setState(() {
        videoHasChanges = true;
      });
    }
  }

  void _drop(int index) {
    video.transcript.removeAt(index);
    video.countTranscript = video.transcript.length;
    setState(() {
      videoHasChanges = true;
    });
  }

  void _join(int index) {
    Transcript transcript1 = video.transcript[index - 1];
    Transcript transcript2 = video.transcript[index];

    transcript1.text = "${transcript1.text} ${transcript2.text}";
    transcript1.duration = transcript2.duration;
    transcript1.controller?.text = transcript1.text;
    _setEnd(transcript1);

    video.transcript.removeAt(index);
    video.countTranscript = video.transcript.length;

    setState(() {
      videoHasChanges = true;
    });
  }

  void listener() {
    if (userVideoLoaded &&
        curPlayerPosition != _controller.value.position.inMilliseconds) {
      curPlayerPosition = _controller.value.position.inMilliseconds;

      if (_isPlayerReady && mounted && pinIndex != -1) {
        final transcript = video.transcript[pinIndex];
        final start = (transcript.start * 1000).toInt();
        final end = ((transcript.start + transcript.duration) * 1000).toInt();
        if (curPlayerPosition < start || curPlayerPosition > end) {
          _controller.seekTo(
              Duration(milliseconds: (transcript.start * 1000).toInt()));
        }
      }

      // TODO: improve lookup algorithm
      int index = video.transcript.indexWhere((e) {
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
      final dur = (video.transcript[pinIndex].start * 1000).toInt();
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
            userVideoLoaded ? video.title : '',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            PopupMenuButton(itemBuilder: (context) {
              List<PopupMenuItem> menus = [];

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
                DropdownButton<String>(
                  value: userVideoLoaded ? video.visibility : 'Private',
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
                      video.visibility = newStatus!;
                      _syncChanges();
                    });
                  },
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
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed:
                  updatingVideo || !videoHasChanges ? null : _syncChanges,
                )
              ],
            ),
            _space,
            Expanded(
              child: (
                userVideoLoaded ?
                ScrollablePositionedList.builder(
                  itemCount: video.transcript.length + 1,
                  itemBuilder: (BuildContext context, int index) {
                    if (index < video.transcript.length) {

                      final Transcript transcript = video.transcript[index];

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
                                Row(
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
                                ListTile(
                                  contentPadding:
                                  const EdgeInsets.only(right: 8, left: 8),
                                  title: TextField(
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
                                  ),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: ElevatedButton(
                          child: Text(AppLocalizations.of(context)!.done),
                          onPressed: () {
                            video.status = Status.TRANSCRIPT_EDITED;
                            _syncChanges().then((value) {
                              Navigator.of(context).pop();
                            });
                          },
                        )
                      );
                    }
                  },
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
                ) :
                const Center(child: CircularProgressIndicator())
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _space => const SizedBox(height: 10);
}
