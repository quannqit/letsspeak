class TranslatedTranscriptResponse {
  TranslatedTranscriptResponse({
    required this.data,
    required this.count,
    required this.total,
    required this.page,
    required this.pageCount,
  });
  late final List<TranslatedTranscript> data;
  late final int count;
  late final int total;
  late final int page;
  late final int pageCount;

  TranslatedTranscriptResponse.fromJson(Map<String, dynamic> json){
    data = List.from(json['data']).map((e)=>TranslatedTranscript.fromJson(e)).toList();
    count = json['count'];
    total = json['total'];
    page = json['page'];
    pageCount = json['pageCount'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['data'] = data.map((e)=>e.toJson()).toList();
    _data['count'] = count;
    _data['total'] = total;
    _data['page'] = page;
    _data['pageCount'] = pageCount;
    return _data;
  }
}

class TranslatedTranscript {
  TranslatedTranscript({
    required this.id,
    required this.videoId,
    required this.language,
    required this.transcript,
  });
  late final int id;
  late final int videoId;
  late final String language;
  late final List<String> transcript;

  TranslatedTranscript.fromJson(Map<String, dynamic> json){
    id = json['id'];
    videoId = json['videoId'];
    language = json['language'];
    transcript = List.castFrom<dynamic, String>(json['transcript']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['videoId'] = videoId;
    _data['language'] = language;
    _data['transcript'] = transcript;
    return _data;
  }
}