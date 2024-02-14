import 'package:letsspeak/data/models/requests/video_request.dart';
import 'package:letsspeak/data/models/transcript.dart';
import 'package:googleapis/youtube/v3.dart' as v3;

class Video {
  Video({
    required this.id,
    required this.title,
    required this.videoId,
    required this.transcript,
    required this.countTranscript,
    required this.youtubeMeta,
    required this.userVideos,
    required this.visibility,
    this.status,
  });

  late final int id;
  late final String videoId;
  late final String title;
  late final bool transcripted;
  late final List<Transcript> transcript;
  late int countTranscript;
  late final v3.Video youtubeMeta;
  List<Map<String, dynamic>> userVideos = [];
  late Status? status;
  late String visibility;

  Video.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    videoId = json['videoId'];
    if (json.containsKey('transcripted')) {
      transcripted = json['transcripted'];
    }
    if (json['transcript'] != null) {
      transcript = List.from(json['transcript'])
          .map((e) => Transcript.fromJson(e))
          .toList();
    }
    countTranscript = json['countTranscript'] ?? 0;
    youtubeMeta = v3.Video.fromJson(json['youtubeMeta']);

    if (json['userVideos'] != null) {
      userVideos.addAll(List.from(json['userVideos']));
    }

    if (json.containsKey('status')) {
      status = Status.values.byName(json['status']);
    }

    visibility = json['visibility'] ?? 'Private';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['videoId'] = videoId;
    data['transcripted'] = transcripted;
    data['transcript'] = transcript.map((e) => e.toJson()).toList();
    data['countTranscript'] = countTranscript;
    data['youtubeMeta'] = youtubeMeta.toJson();
    data['userVideo'] = userVideos.toList();
    data['visibility'] = visibility;
    data['status'] = status?.value;
    return data;
  }
}
