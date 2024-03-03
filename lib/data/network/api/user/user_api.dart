import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/constant/endpoints.dart';
import 'package:letsspeak/data/network/dio_client.dart';

class UserApi {
  final DioClient dioClient;

  UserApi({required this.dioClient});

  Future<Response> addUserApi() async {
    return await dioClient.post(Endpoints.users);
  }

  Future<Response> addVideo(int videoId) async {
    return await dioClient.post(
        '${Endpoints.userVideo}/add-videos-to-learning-list',
        data: {"videoIds": [videoId]}
    );
  }

  Future<Response> setLanguage(String lang) async {
    return await dioClient.patch(
        '${Endpoints.users}/me',
        data: {"language": lang}
    );
  }

  Future<Response> delete() async {
    return await dioClient.delete(Endpoints.users);
  }

}
