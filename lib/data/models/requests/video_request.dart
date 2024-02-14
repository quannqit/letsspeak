enum Status {
  RECEIVED('RECEIVED'),
  TRANSCRIPT_GENERATED('TRANSCRIPT_GENERATED'),
  TRANSCRIPT_EDITED('TRANSCRIPT_EDITED'),
  TRANSCRIPT_TRANSLATED('TRANSCRIPT_TRANSLATED'),
  PUBLISHED('PUBLISHED');

  const Status(this.value);
  final String value;
}

class VideosRequest {
  VideosRequest({
    this.status,
    this.sort,
    required this.page,
    required this.limit,
  });

  late Status? status;
  late String? sort;
  late final int page;
  late final int limit;

  VideosRequest.fromJson(Map<String, dynamic> json) {
    page = json['page'];
    limit = json['limit'];
    sort = json['sort'];
    status = Status.values.byName(json['status']);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (sort != null) {
      data['sort'] = sort;
    }
    data['status'] = status?.value;
    data['page'] = page;
    data['limit'] = limit;
    return data;
  }
}
