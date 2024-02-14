import 'package:letsspeak/data/models/user_video.dart';
import 'package:letsspeak/data/models/responses/user_video_response.dart';
import 'package:letsspeak/data/network/api/user_video/user_video_api.dart';

class UserVideoRepository {
  final UserVideoApi userVideoApi;

  UserVideoRepository(this.userVideoApi);

  Future<UserVideoResponse> getMyVideosApi(int page) async {
    final response = await userVideoApi.getMyVideosApi(page);
    return UserVideoResponse.fromJson(response.data);
  }

  Future<UserVideo> getUserVideosApi(int id) async {
    final response = await userVideoApi.getUserVideosApi(id);
    return UserVideo.fromJson(response.data);
  }

  Future<void> updateUserVideosApi(UserVideo userVideo) async {
    await userVideoApi.updateUserVideosApi(userVideo);
  }
}
