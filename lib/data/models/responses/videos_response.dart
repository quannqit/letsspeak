import 'package:letsspeak/data/models/video.dart';

class VideosResponse {
  VideosResponse({
    required this.data,
    required this.count,
    required this.total,
    required this.page,
    required this.pageCount,
  });
  late final List<Video> data;
  late final int count;
  late final int total;
  late final int page;
  late final int pageCount;

  VideosResponse.fromJson(Map<String, dynamic> json){
    data = List.from(json['data']).map((e)=> Video.fromJson(e)).toList();
    count = json['count'];
    total = json['total'];
    page = json['page'];
    pageCount = json['pageCount'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['data'] = data.map((video)=>video.toJson()).toList();
    _data['count'] = count;
    _data['total'] = total;
    _data['page'] = page;
    _data['pageCount'] = pageCount;
    return _data;
  }
}