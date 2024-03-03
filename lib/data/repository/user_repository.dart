import 'package:letsspeak/data/models/user/new_user_model.dart';
import 'package:letsspeak/data/network/api/user/user_api.dart';

class UserRepository {
  final UserApi userApi;

  UserRepository(this.userApi);

  Future<NewUser> addNewUserRequested() async {
    final response = await userApi.addUserApi();
    return NewUser.fromJson(response.data);
  }

  Future<void> addVideo(int videoId) async {
    await userApi.addVideo(videoId);
  }

  Future<void> setLanguage(String lang) async {
    await userApi.setLanguage(lang);
  }

  Future<void> deleteAccount() async {
    await userApi.delete();
  }

}
