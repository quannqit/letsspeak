import 'package:letsspeak/data/models/responses/user_data_response.dart';
import 'package:letsspeak/data/models/user/new_user_model.dart';
import 'package:letsspeak/data/models/responses/user_video_response.dart';
import 'package:letsspeak/data/models/video.dart';
import 'package:letsspeak/data/repository/auth_repository.dart';
import 'package:letsspeak/data/repository/translated_transcript_repository.dart';
import 'package:letsspeak/data/repository/user_repository.dart';
import 'package:letsspeak/data/repository/user_video_repository.dart';
import 'package:letsspeak/data/repository/video_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:flutter/material.dart';

import '../../data/models/responses/translated_transcript_response.dart';
import '../../data/models/user_video.dart';

class HomeController {
  // --------------- Repository -------------
  final authRepository = getIt.get<AuthRepository>();
  final userRepository = getIt.get<UserRepository>();
  final videoRepository = getIt.get<VideoRepository>();
  final userVideoRepository = getIt.get<UserVideoRepository>();
  final translatedTranscriptRepository = getIt.get<TranslatedTranscriptRepository>();

  // -------------- Textfield Controller ---------------
  final nameController = TextEditingController();
  final jobController = TextEditingController();

  // -------------- Local Variables ---------------
  final List<NewUser> newUsers = [];

  // -------------- Methods ---------------

  Future<UserDataResponse> getUserDataApi() async {
    return await authRepository.getUserDataApi();
  }

  Future<UserVideoResponse> getMyVideosApi(int page) async {
    return await userVideoRepository.getMyVideosApi(page);
  }

  Future<UserVideo> getUserVideosApi(int id) async {
    return await userVideoRepository.getUserVideosApi(id);
  }

  Future<void> updateUserVideosApi(UserVideo userVideo) async {
    await userVideoRepository.updateUserVideosApi(userVideo);
  }

  Future<Video> getVideo(int videoId) async {
    return await videoRepository.getVideo(videoId);
  }

  Future<TranslatedTranscriptResponse> getTranslatedTranscriptsApi(int videoId, String lang) async {
    return await translatedTranscriptRepository.getTranslatedTranscriptsApi(videoId, lang);
  }

  Future<void> updateVideo(Video video) async {
    await videoRepository.updateVideo(video);
  }

  Future<NewUser> addNewUser() async {
    final newlyAddedUser = await userRepository.addNewUserRequested();
    newUsers.add(newlyAddedUser);
    return newlyAddedUser;
  }

  Future<void> setLanguage(String lang) async {
    await userRepository.setLanguage(lang);
  }

  Future<void> translate(int videoId) async {
    await videoRepository.translate(videoId);
  }

}
