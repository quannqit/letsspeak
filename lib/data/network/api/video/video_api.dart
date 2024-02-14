import 'dart:collection';

import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/video.dart';
import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/constant/endpoints.dart';
import 'package:letsspeak/data/network/dio_client.dart';

class VideoApi {
  final DioClient dioClient;

  VideoApi({required this.dioClient});

  Future<Response> getVideos(VideosRequest request) async {
    return await dioClient.get(Endpoints.videos,
        queryParameters: request.toJson());
  }

  Future<Response> getVideo(int videoId) async {
    return await dioClient.get("${Endpoints.videos}/$videoId");
  }

  Future<Response> updateVideo(Video video) async {
    return await dioClient.patch("${Endpoints.videos}/${video.id}",
        options: Options(headers: {"Content-Type": "application/json"}),
        data: video.toJson());
  }

  Future<Response> addVideo(String videoId) async {
    return await dioClient.post(
        Endpoints.videos,
        options: Options(headers: {"Content-Type": "application/json"}),
        data: {"videoId": videoId}
    );
  }

  Future<Response> translate(int videoId) async {
    return await dioClient.post("${Endpoints.videos}/$videoId/translate",
    options: Options(receiveTimeout: const Duration(seconds: 120)));
  }

}
