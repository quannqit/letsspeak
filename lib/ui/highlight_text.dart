import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Defines what occurrence you want to highlight
enum HighlightBinding {
  /// Highlights all occurrences of a word
  all,

  /// Highlights only the first occurrence
  first,

  /// Highlights only the last occurrence
  last,
}

/// It stores the layout data about a word
class HighlightedWord {
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? padding;

  HighlightedWord({
    this.textStyle,
    this.onTap,
    this.decoration,
    this.padding,
  });
}

/// TextHighlight will provide you a easy way to display highlighted words on your app
class TextHighlight extends StatelessWidget {
  /// The text you want to show
  final String text;

  /// Map with the word you need to highlight
  final Map<String, HighlightedWord> words;

  /// Split the highlighted word to fit in the same line as the text
  final bool splitOnLongWord;

  /// Change the alignment of the text inside span
  final PlaceholderAlignment spanAlignment;

  /// If it is true, it will highlight the exactly same match
  final bool matchCase;

  /// Change the occurrence of a highlight
  final HighlightBinding binding;

  final TextStyle? textStyle;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool softWrap;
  final TextOverflow overflow;
  final double textScaleFactor;
  final int? maxLines;
  final Locale? locale;
  final StrutStyle? strutStyle;

  final Map<String, List<String>> _originalWords = <String, List<String>>{};

  TextHighlight({
    super.key,
    required this.text,
    required this.words,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.matchCase = false,
    this.binding = HighlightBinding.all,
    this.spanAlignment = PlaceholderAlignment.middle,
    this.splitOnLongWord = false,
  });

  @override
  Widget build(BuildContext context) {
    List<String> textWords = _bind();

    return RichText(
      text: _buildSpan(textWords),
      locale: locale,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
    );
  }

  String _multipleBinding() {
    String boundText = text;
    final Map<int, Match> allMatchesByStartIndex = <int, Match>{};

    for (String word in words.keys) {
      _originalWords[word] = <String>[];

      Iterable<Match> wordMatches = matchCase
          ? word.allMatches(text)
          : word.toLowerCase().allMatches(text.toLowerCase());

      for (Match match in wordMatches) {
        if (match[0] != null && _isMatchWholeWord(text, match)) {
          // If a match with the same start as the current match is already
          // known, but the current match is longer, replace the known match.
          // Otherwise do nothing, because otherwise this would
          // attempt to highlight a sub-word in an already highlighted word,
          // which would break the <highlight> syntax.
          Match? knownMatch = allMatchesByStartIndex[match.start];
          if (knownMatch == null || match[0]!.length > knownMatch[0]!.length) {
            _originalWords[word]!.add(text.substring(match.start, match.end));
            allMatchesByStartIndex[match.start] = match;
          }
        }
      }
    }

    final List<String> sourceWords = matchCase
        ? words.keys.toList()
        : words.keys.map((w) => w.toLowerCase()).toList();

    // sort by start descending to replace from right to left
    final List<Match> allMatches = allMatchesByStartIndex.values.toList();
    allMatches.sort((m1, m2) => m2.start.compareTo(m1.start));

    for (Match match in allMatches) {
      boundText = boundText.replaceRange(
        match.start,
        match.end,
        '|${sourceWords.indexOf(match[0]!)}|',
      );
    }

    return boundText;
  }

  bool _isMatchWholeWord(String text, Match match) {
    String matchString = text.substring(match.start, match.end);
    String test = text.substring(math.max(0, match.start - 1), math.min(text.length, match.end + 1)).trim();
    return matchString == test;
  }

  String _firstWordBinding() {
    String boundText = text;

    for (String word in words.keys) {
      _originalWords.addAll({word: <String>[]});

      if (matchCase) {
        int strIndex = boundText.indexOf(word);
        int strLastIndex = strIndex + word.length;
        boundText = boundText.replaceRange(
            strIndex, strLastIndex, '|${words.keys.toList().indexOf(word)}|');
      } else {
        int strIndex = boundText.toLowerCase().indexOf(word.toLowerCase());
        int strLastIndex = strIndex + word.length;
        if (strIndex >= 0) {
          _originalWords[word]!
              .add(boundText.substring(strIndex, strIndex + word.length));

          boundText = boundText.replaceRange(
              strIndex, strLastIndex, '|${words.keys.toList().indexOf(word)}|');
        }
      }
    }

    return boundText;
  }

  String _lastWordBinding() {
    String boundText = text;

    for (String word in words.keys) {
      _originalWords.addAll({word: <String>[]});

      if (matchCase) {
        int strIndex = boundText.lastIndexOf(word);
        int strLastIndex = strIndex + word.length;
        boundText = boundText.replaceRange(
            strIndex, strLastIndex, '|${words.keys.toList().indexOf(word)}|');
      } else {
        int strIndex = boundText.toLowerCase().lastIndexOf(word.toLowerCase());
        int strLastIndex = strIndex + word.length;
        if (strIndex >= 0) {
          _originalWords[word]!
              .add(boundText.substring(strIndex, strIndex + word.length));

          boundText = boundText.replaceRange(
              strIndex, strLastIndex, '|${words.keys.toList().indexOf(word)}|');
        }
      }
    }

    return boundText;
  }

  List<String> _bind() {
    String boundWords;

    switch (binding) {
      case HighlightBinding.first:
        boundWords = _firstWordBinding();
        break;
      case HighlightBinding.last:
        boundWords = _lastWordBinding();
        break;
      case HighlightBinding.all:
      default:
        boundWords = _multipleBinding();
    }

    List<String> splitTexts = boundWords.split("|");
    splitTexts.removeWhere((s) => s.isEmpty);

    return splitTexts;
  }

  TextSpan _buildSpan(List<String> boundWords) {
    if (boundWords.isEmpty) {
      final thumbUp = isThumbUp();
      return TextSpan(
        text: " ${matchPercentage().toStringAsFixed(2)}%",
        style: TextStyle(
            color: thumbUp ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
        ),
      );
    }

    String nextToDisplay = boundWords.first;
    boundWords.removeAt(0);

    int? index = int.tryParse(nextToDisplay);

    // if (index != null) {
    try {
      String currentWord = words.keys.toList()[index!];
      String showWord;
      if (matchCase) {
        showWord = currentWord;
      } else {
        showWord = _originalWords[currentWord]!.first;
        _originalWords[currentWord]!.removeAt(0);
      }
      final List<String> splittedWords = [];
      if (splitOnLongWord && showWord.contains(" ")) {
        for (String w in showWord.split(" ")) {
          splittedWords.addAll([w, " "]);
        }
      } else {
        splittedWords.add(showWord);
      }

      return TextSpan(
        children: [
          for (String w in splittedWords)
            if (w == " ")
              _buildSpan([" "])
            else
              WidgetSpan(
                alignment: spanAlignment,
                child: GestureDetector(
                  onTap: words[currentWord]!.onTap,
                  child: Container(
                    padding: words[currentWord]!.padding,
                    decoration: words[currentWord]!.decoration,
                    child: Text(
                      w,
                      style: words[currentWord]!.textStyle ?? textStyle,
                      textScaleFactor: 1.0,
                    ),
                  ),
                ),
              ),
          _buildSpan(boundWords),
        ],
      );
    } catch (e) {
      return TextSpan(
        text: nextToDisplay,
        style: textStyle,
        children: [
          _buildSpan(boundWords),
        ],
      );
    }
    // }

    // return TextSpan(
    //   text: nextToDisplay,
    //   style: textStyle,
    //   children: [
    //     _buildSpan(boundWords),
    //   ],
    // );
  }

  double matchPercentage () {
    final splitTexts = _bind();
    splitTexts.retainWhere((text) => text.contains(RegExp(r"\d+")));
    return splitTexts.length.toDouble() / words.length * 100;
  }

  bool isThumbUp () {
    return matchPercentage() >= 70;
  }

}