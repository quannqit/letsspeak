import 'package:letsspeak/data/network/api/auth/auth.dart';
import 'package:letsspeak/data/network/api/translated_transcript/translated_transcript_api.dart';
import 'package:letsspeak/data/network/api/user_video/user_video_api.dart';
import 'package:letsspeak/data/network/api/video/video_api.dart';
import 'package:letsspeak/data/repository/auth_repository.dart';
import 'package:letsspeak/data/repository/translated_transcript_repository.dart';
import 'package:letsspeak/data/repository/user_video_repository.dart';
import 'package:letsspeak/data/repository/video_repository.dart';
import 'package:letsspeak/ui/marketplace/marketplace_controller.dart';
import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/user/user_api.dart';
import 'package:letsspeak/data/network/dio_client.dart';
import 'package:letsspeak/data/repository/user_repository.dart';
import 'package:letsspeak/ui/home/controller.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  getIt.registerSingleton(Dio());
  getIt.registerSingleton(DioClient(getIt<Dio>()));

  getIt.registerSingleton(AuthApi(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(AuthRepository(getIt.get<AuthApi>()));

  getIt.registerSingleton(UserApi(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(UserRepository(getIt.get<UserApi>()));

  getIt.registerSingleton(VideoApi(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(VideoRepository(getIt.get<VideoApi>()));

  getIt.registerSingleton(UserVideoApi(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(UserVideoRepository(getIt.get<UserVideoApi>()));

  getIt.registerSingleton(TranslatedTranscriptApi(dioClient: getIt<DioClient>()));
  getIt.registerSingleton(TranslatedTranscriptRepository(getIt.get<TranslatedTranscriptApi>()));

  getIt.registerSingleton(HomeController());
  getIt.registerSingleton(MarketplaceController());

  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton(prefs);

}
