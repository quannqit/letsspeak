import 'dart:async';
import 'dart:math';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/models/user_video.dart';
import 'package:letsspeak/data/models/responses/user_video_response.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:letsspeak/ui/home/controller.dart';
import 'package:letsspeak/ui/home/widgets/app_bar.dart';
import 'package:letsspeak/ui/marketplace/marketplace_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:iso8601_duration/iso8601_duration.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../data/repository/video_repository.dart';
import '../add_video/add_video_page.dart';
import 'choose_language_dropdown.dart';
import '../login/login_page.dart';
import '../story/youtube_player_page.dart';
import 'expandable_fab.dart';

class HomePage extends StatefulWidget {

  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final homeController = getIt<HomeController>();
  final videoRepository = getIt.get<VideoRepository>();

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late ScrollController scrollController;

  late UserDataResponse userData;
  List<UserVideo> listUserVideo = [];
  Future<void>? _initRemoteData;

  int curPage = 1;
  int limit = 10;
  int pageCount = 0;
  bool loading = false;

  String? dropdownValue;
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scrollController = ScrollController()..addListener(_scrollListener);
    _initRemoteData = _loadRemoteData();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.getMediaStream().listen(handleReceiveIntent);

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.getInitialMedia().then(handleReceiveIntent);
  }

  @override
  void dispose() {
    _intentSub.cancel();
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadRemoteData();
    }
  }

  Future<void> _loadRemoteData() async {
    setState(() {
      listUserVideo.clear();
      loading = true;
    });

    userData = await homeController.getUserDataApi();

    if (userData.firstLanguage == null) {
      showChooseFirstLanguage();
    }

    curPage = 1;
    final UserVideoResponse res = await homeController.getMyVideosApi(curPage);
    pageCount = res.pageCount;

    setState(() {
      listUserVideo.addAll(res.data);
      loading = false;
    });
  }

  void _scrollListener() {
    if (scrollController.position.extentAfter < 500) {
      if (!loading && pageCount.compareTo(curPage) == 1) {
        _loadMore();
      }
    }
  }

  _loadMore() async {
    setState(() {
      loading = true;
    });
    curPage = curPage + 1;
    final res = await homeController.getMyVideosApi(curPage);
    listUserVideo.addAll(res.data);

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: const BaseAppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user.displayName ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                user.email ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                backgroundColor: Colors.yellow,
                child: user.photoURL == null
                    ? Text(
                        user.displayName?.splitMapJoin(
                              RegExp(r'\S+'),
                              onMatch: (m) => '${m[0]?[0].toUpperCase()}',
                              onNonMatch: (m) => '',
                            ) ??
                            '',
                        style: Theme.of(context).textTheme.displaySmall,
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: Text(AppLocalizations.of(context)!.public_video),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MarketplacePage(userData, Status.PUBLISHED, AppLocalizations.of(context)!.public_video),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie),
              title: Text(AppLocalizations.of(context)!.your_videos),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () {
                FirebaseAuth.instance.signOut().then((value) {
                  GoogleSignIn().signOut();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                });
              },
            ),
            AboutListTile(
              icon: const Icon(Icons.info),
              applicationIcon: const Icon(Icons.local_play),
              applicationName: AppLocalizations.of(context)!.app_name,
              applicationVersion: '0.0.1',
              applicationLegalese: '© 2023 QuanNQ.Dev',
              aboutBoxChildren: [],
              child: Text(
                AppLocalizations.of(context)!.about,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _initRemoteData,
        builder: (context, snapshot) {

          final ISODurationConverter converter = ISODurationConverter();

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              {
                return const Center(child: CircularProgressIndicator());
              }
            case ConnectionState.done:
              {
                return RefreshIndicator(
                  key: _refreshIndicatorKey,
                  onRefresh: _loadRemoteData,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: listUserVideo.isEmpty && !loading
                        ? Center(
                            child: ElevatedButton(
                              child: Text(AppLocalizations.of(context)!.go_to_marketplace),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MarketplacePage(userData, Status.PUBLISHED, AppLocalizations.of(context)!.public_video),
                                  ),
                                ).then((value) {
                                  _loadRemoteData();
                                });
                              },
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: listUserVideo.length + (loading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == listUserVideo.length) {
                                return const Center(
                                  child: SpinKitThreeBounce(
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                );
                              }

                              final userVideo = listUserVideo[index];
                              final video = userVideo.video;
                              final snippet = userVideo.video.youtubeMeta.snippet;
                              var thumbnailsUrl = snippet?.thumbnails?.standard?.url ?? '';
                              if (thumbnailsUrl == '') {
                                thumbnailsUrl = snippet?.thumbnails?.default_?.url ?? '';
                              }
                              if (thumbnailsUrl == '') {
                                if (kDebugMode) {
                                  print(snippet?.thumbnails?.toJson());
                                }
                              }
                              final ISODuration duration = converter.parseString(isoDurationString: userVideo.video.youtubeMeta.contentDetails?.duration ?? '');
                              final String dur = "${duration.minute.toString().padLeft(2, '0')}:${duration.seconds.toString().padLeft(2, '0')}";

                              return Card(
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(8.0),
                                      leading: thumbnailsUrl == '' ? null : Image(image: NetworkImage(thumbnailsUrl)),
                                      title: Text(
                                        video.title,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: LinearPercentIndicator(
                                        animation: true,
                                        lineHeight: 16.0,
                                        padding: const EdgeInsets.only(left: 8),
                                        leading: Text(dur),
                                        percent:
                                        userVideo.countPractisedSentences /
                                            max(userVideo.countPractisedSentences, max(1, video.countTranscript)),
                                        center: Text(
                                          AppLocalizations.of(context)!
                                              .x_y_sentences(
                                            userVideo.countPractisedSentences,
                                            video.countTranscript,
                                          ),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        barRadius: const Radius.circular(10),
                                        progressColor: Colors.greenAccent,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          CupertinoPageRoute(
                                            builder: (context) => YoutubePlayerPage(
                                              userData: userData,
                                              userVideoId: userVideo.id,
                                              youtubeVideoId: video.videoId,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                );
              }
          }
        },
      ),
      floatingActionButton: ExpandableFab(
          distance: 112,
          children: [
            ActionButton(
              onPressed: () {
                navigateToShareText(context, "");
              },
              icon: const Icon(Icons.add_link),
            ),
          ]
      )
    );
  }

  showChooseFirstLanguage() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () => Future.value(false),
          child: AlertDialog(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  20.0,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.only(
              top: 10.0,
            ),
            title: Text(
              AppLocalizations.of(context)!.choose_first_language,
              style: const TextStyle(fontSize: 24.0),
            ),
            content: SizedBox(
              child: ChooseLanguageDropdown(
                onSelect: (String lang) {
                  if (kDebugMode) {
                    print("lang: $lang");
                  }
                  homeController.setLanguage(lang);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void handleReceiveIntent(List<SharedMediaFile> values) {
    if (mounted && values.isNotEmpty) {
      navigateToShareText(context, values[0].path);
    }
  }

  void navigateToShareText(BuildContext context, String? videoId) {
    if (videoId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddVideoPage(videoId),
        ),
      ).then((value) {
        _loadRemoteData();
      });
    }
  }
}
