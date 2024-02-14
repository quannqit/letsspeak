import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/constant/endpoints.dart';
import 'package:letsspeak/data/network/dio_client.dart';

class AuthApi {
  final DioClient dioClient;

  AuthApi({required this.dioClient});

  Future<Response> getUserDataApi() async {
    return await dioClient.get('${Endpoints.auth}/me');
  }

}
