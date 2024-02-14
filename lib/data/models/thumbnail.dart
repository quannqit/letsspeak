class Thumbnail {
  Thumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  late final String url;
  late final int width;
  late final int height;

  Thumbnail.fromJson(Map<String, dynamic> json) {
    url = json['url'];
    width = json['width'];
    height = json['height'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['url'] = url;
    data['width'] = width;
    data['height'] = height;
    return data;
  }
}
