import 'package:letsspeak/data/models/user_video.dart';
import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/constant/endpoints.dart';
import 'package:letsspeak/data/network/dio_client.dart';

class UserVideoApi {
  final DioClient dioClient;

  UserVideoApi({required this.dioClient});

  Future<Response> getMyVideosApi(int page) async {
    return await dioClient.get(
        Endpoints.userVideo,
        queryParameters: {
          "page": page
        }
    );
  }

  Future<Response> getUserVideosApi(int id) async {
    return await dioClient.get('${Endpoints.userVideo}/$id');
  }

  Future<Response> updateUserVideosApi(UserVideo userVideo) async {
    return await dioClient.patch('${Endpoints.userVideo}/${userVideo.id}', data: userVideo.toJson());
  }
}
