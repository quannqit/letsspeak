import 'package:letsspeak/data/models/video.dart';

class UserVideo {
  UserVideo({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.video,
    required this.recognizedWords,
    required this.countPractisedSentences,
  });

  late final int id;
  late final int userId;
  late final int videoId;
  late final Video video;
  late final Map<String, dynamic> recognizedWords;
  int countPractisedSentences = 0;

  UserVideo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    videoId = json['videoId'];
    video = Video.fromJson(json['video']);
    if (json['recognizedWords'] != null) {
      recognizedWords = json['recognizedWords'];
      countPractisedSentences = json['countPractisedSentences'] ?? 0;
    } else {
      recognizedWords = {};
      countPractisedSentences = 0;
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['videoId'] = videoId;
    data['recognizedWords'] = recognizedWords;
    data['countPractisedSentences'] = countPractisedSentences;
    data['video'] = video.toJson();
    return data;
  }
}
