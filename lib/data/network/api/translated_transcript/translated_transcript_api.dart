import 'package:dio/dio.dart';
import 'package:letsspeak/data/network/api/constant/endpoints.dart';
import 'package:letsspeak/data/network/dio_client.dart';

class TranslatedTranscriptApi {
  final DioClient dioClient;

  TranslatedTranscriptApi({required this.dioClient});

  Future<Response> getTranslatedTranscriptsApi(int videoId, String lang) async {
    return await dioClient.get(
        Endpoints.translatedTranscript,
        queryParameters: {
          "filter": ["videoId||\$eq||$videoId", "language||\$eq||$lang"]
        }
    );
  }

}
