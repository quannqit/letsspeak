import 'package:letsspeak/data/models/responses/translated_transcript_response.dart';
import 'package:letsspeak/data/network/api/translated_transcript/translated_transcript_api.dart';

class TranslatedTranscriptRepository {
  final TranslatedTranscriptApi translatedTranscriptApi;
  TranslatedTranscriptRepository(this.translatedTranscriptApi);

  Future<TranslatedTranscriptResponse> getTranslatedTranscriptsApi(int videoId, String lang) async {
    final response = await translatedTranscriptApi.getTranslatedTranscriptsApi(videoId, lang);
    return TranslatedTranscriptResponse.fromJson(response.data);
  }

}
