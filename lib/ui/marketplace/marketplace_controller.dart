import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/user/new_user_model.dart';
import 'package:letsspeak/data/models/responses/videos_response.dart';
import 'package:letsspeak/data/repository/user_repository.dart';
import 'package:letsspeak/data/repository/video_repository.dart';
import 'package:letsspeak/di/service_locator.dart';
import 'package:flutter/material.dart';

class MarketplaceController {
  // --------------- Repository -------------
  final userRepository = getIt.get<UserRepository>();
  final videoRepository = getIt.get<VideoRepository>();

  // -------------- Textfield Controller ---------------
  final nameController = TextEditingController();
  final jobController = TextEditingController();

  // -------------- Local Variables ---------------
  final List<NewUser> newUsers = [];

  // -------------- Methods ---------------

  Future<VideosResponse> getVideos(Status status, int page, int limit) async {
    return await videoRepository.getVideos(VideosRequest(
      status: status,
      sort: "created,DESC",
      page: page,
      limit: limit,
    ));
  }

  Future<void> addVideo(int videoId) async {
    await userRepository.addVideo(videoId);
  }

}
