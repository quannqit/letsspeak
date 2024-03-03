import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final Map<String, String> languages = HashMap()
  ..addAll({
    'zh': '中國人',
    'hi': 'हिंदी',
    'es': 'Español',
    'fr': 'Français',
    'ar': 'عربي',
    'bn': 'বাংলা',
    'ru': 'Русский',
    'pt': 'Português',
    'id': 'Bahasa Indonesia',
    'vi': 'Tiếng Việt'
  });

class ChooseLanguageDropdown extends StatefulWidget {
  final void Function(String lang) onSelect;
  final String? dropdownValue;

  const ChooseLanguageDropdown({
    required this.onSelect,
    this.dropdownValue,
    Key? key,
  }) : super(key: key);

  @override
  State<ChooseLanguageDropdown> createState() => _ChooseLanguageDropdownState();
}

class _ChooseLanguageDropdownState extends State<ChooseLanguageDropdown> {
  String? dropdownValue;

  @override
  void initState() {
    dropdownValue = widget.dropdownValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: dropdownValue,
              hint: const Text("Your first language"),
              items: languages
                  .map<String, DropdownMenuItem<String>>(
                      (String key, String value) {
                    return MapEntry(
                        key,
                        DropdownMenuItem<String>(
                          value: key,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 30),
                          ),
                        ));
                  })
                  .values
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  dropdownValue = newValue!;
                });
              },
              isExpanded: true,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: dropdownValue == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      widget.onSelect(dropdownValue!);
                    },
              child: Text(AppLocalizations.of(context)!.submit),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(AppLocalizations.of(context)!.note),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppLocalizations.of(context)!.choose_first_language_desc,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
