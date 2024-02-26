import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/models/video.dart';
import 'package:letsspeak/ui/dialog.dart';
import 'package:letsspeak/ui/marketplace/marketplace_controller.dart';
import 'package:letsspeak/ui/story/edit_transcript_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../di/service_locator.dart';
import '../home/controller.dart';

class MarketplacePage extends StatefulWidget {

  final Status status;
  final String title;

  const MarketplacePage(this.status, this.title, {super.key});

  @override
  State<StatefulWidget> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final homeController = getIt<HomeController>();
  final marketplaceController = getIt<MarketplaceController>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  late ScrollController scrollController;

  final List<Video> videos = [];
  late Future<void>? _initVideoData;
  int curPage = 1;
  int limit = 10;
  int pageCount = 0;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController()..addListener(_scrollListener);

    _initVideoData = _loadVideos();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  Future<void> _loadVideos() async {
    curPage = 1;
    loading = true;
    setState(() {});

    videos.clear();
    final res = await marketplaceController.getVideos(widget.status, curPage, limit);
    videos.addAll(res.data);
    pageCount = res.pageCount;

    loading = false;
    setState(() {});
  }

  _loadMore() async {
    loading = true;
    curPage = curPage + 1;

    setState(() {});
    final res = await marketplaceController.getVideos(widget.status, curPage, limit);
    videos.addAll(res.data);
    loading = false;
    setState(() {});
  }

  void _scrollListener() {
    if (scrollController.position.extentAfter < 500) {
      if (!loading && pageCount.compareTo(curPage) == 1) {
        _loadMore();
      }
    }
  }

  _addVideo(final Video video) {
    marketplaceController.addVideo(video.id).then((value) {
      video.userVideos.add({"videoId": video.id});
      setState(() {});
      showMyDialog(context, AppLocalizations.of(context)!.video_added(video.title));
    });
  }

  _translate(final Video video) {
    homeController.translate(video.id).then((value) {
      showMyDialog(context, AppLocalizations.of(context)!.video_translated(video.title));
      _loadVideos();
    });
  }

  _publish(final Video video) {
    homeController.getVideo(video.id).then((video) {
      video.status = Status.PUBLISHED;
      video.visibility = 'Public';
      homeController.updateVideo(video).then((value) {
        showMyDialog(context, AppLocalizations.of(context)!.video_publish(video.title));
        _loadVideos();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<void>(
        future: _initVideoData,
        builder: (context, snapshot) {
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
                  onRefresh: _loadVideos,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: videos.length + (loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == videos.length) {
                          return const Center(
                              child: SpinKitThreeBounce(
                            color: Colors.green,
                            size: 30,
                          ));
                        }

                        final video = videos[index];
                        Widget? trailing;
                        switch (widget.status) {
                          case Status.RECEIVED:
                          case Status.TRANSCRIPT_GENERATED: {
                            trailing = ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditTranscriptPage(
                                          youtubeVideoId: video.videoId,
                                          videoId: video.id,
                                        ),
                                  ),
                                );
                              },
                              child: const Text("Edit"),
                            );
                          }
                          break;
                          case Status.TRANSCRIPT_EDITED: {
                            trailing = ElevatedButton(
                              onPressed: () {
                                _translate(video);
                              },
                              child: const Text("Translate"),
                            );
                          }
                          break;
                          case Status.TRANSCRIPT_TRANSLATED: {
                            trailing = ElevatedButton(
                              onPressed: () {
                                _publish(video);
                              },
                              child: const Text("Publish"),
                            );
                          }
                          break;
                          case Status.PUBLISHED: {
                            trailing = video.userVideos.isEmpty ?
                            ElevatedButton(
                              onPressed: () {
                                _addVideo(video);
                              },
                              child: Text(AppLocalizations.of(context)!.add_to_my_video_list),
                            ) :
                            const IconButton(
                              color: Colors.green,
                              icon: Icon(Icons.done),
                              onPressed: null,
                            );
                          }
                          break;
                        }

                        return Card(
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(8.0),
                                leading: Image(image: NetworkImage(video.youtubeMeta.snippet!.thumbnails!.standard!.url!)),
                                title: Text(
                                  video.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: null,
                                trailing: trailing,
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
    );
  }
}
