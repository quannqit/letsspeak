import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/network/api/auth/auth.dart';

class AuthRepository {
  final AuthApi authApi;
  AuthRepository(this.authApi);

  Future<UserDataResponse> getUserDataApi() async {
    final response = await authApi.getUserDataApi();
    return UserDataResponse.fromJson(response.data);
  }

}
