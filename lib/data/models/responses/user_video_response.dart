import 'package:letsspeak/data/models/user_video.dart';

class UserVideoResponse {
  UserVideoResponse({
    required this.data,
    required this.count,
    required this.total,
    required this.page,
    required this.pageCount,
  });

  late final List<UserVideo> data;
  late final int count;
  late final int total;
  late final int page;
  late final int pageCount;

  UserVideoResponse.fromJson(Map<String, dynamic> json) {
    data = List.from(json['data']).map((e) => UserVideo.fromJson(e)).toList();
    count = json['count'];
    total = json['total'];
    page = json['page'];
    pageCount = json['pageCount'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['data'] = this.data.map((e) => e.toJson()).toList();
    data['count'] = count;
    data['total'] = total;
    data['page'] = page;
    data['pageCount'] = pageCount;
    return data;
  }
}
