import 'package:flutter/cupertino.dart';

class Transcript {
  Transcript({
    required this.text,
    required this.start,
    required this.tokens,
    required this.duration,
    required this.translatedText,
    this.controller,
  });

  late String text;
  late num start;
  late final List<String> tokens;
  late num duration;
  late final String? translatedText;
  late final TextEditingController? controller;

  num end() {
    return start + duration;
  }

  Transcript.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    start = json['start'];
    tokens = List.castFrom<dynamic, String>(json['tokens']);
    duration = json['duration'];
    translatedText = json['translatedText'];
    controller = TextEditingController(text: text);
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['text'] = text;
    data['start'] = start;
    data['tokens'] = tokens;
    data['duration'] = duration;
    data['translatedText'] = translatedText;
    return data;
  }
}
