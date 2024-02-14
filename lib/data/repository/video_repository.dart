import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/video.dart';
import 'package:letsspeak/data/models/responses/videos_response.dart';
import 'package:dio/dio.dart';

import '../network/api/video/video_api.dart';

class VideoRepository {
  final VideoApi videoApi;

  VideoRepository(this.videoApi);

  getVideos(VideosRequest request) async {
    final json = await videoApi.getVideos(request);
    return VideosResponse.fromJson(json.data);
  }

  Future<Video> getVideo(int videoId) async {
    final response = await videoApi.getVideo(videoId);
    return Video.fromJson(response.data);
  }

  Future<void> updateVideo(Video video) async {
    await videoApi.updateVideo(video);
  }

  Future<Response> addVideo(String videoId) async {
    return await videoApi.addVideo(videoId);
  }

  Future<Response> translate(int videoId) async {
    return await videoApi.translate(videoId);
  }

}
