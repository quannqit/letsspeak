import 'package:letsspeak/data/models/thumbnail.dart';

class Thumbnails {
  Thumbnails({
    required this.def,
    required this.medium,
    required this.high,
    required this.standard,
  });

  late final Thumbnail def;
  late final Thumbnail medium;
  late final Thumbnail high;
  late final Thumbnail standard;

  Thumbnails.fromJson(Map<String, dynamic> json) {
    def = Thumbnail.fromJson(json['default']);
    medium = Thumbnail.fromJson(json['medium']);
    high = Thumbnail.fromJson(json['high']);
    standard = Thumbnail.fromJson(json['standard']);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['default'] = def.toJson();
    data['medium'] = medium.toJson();
    data['high'] = high.toJson();
    data['standard'] = standard.toJson();
    return data;
  }
}
