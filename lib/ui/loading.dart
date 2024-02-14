import 'package:flutter/material.dart';

showLoadingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              // The loading indicator
              CircularProgressIndicator(),
              SizedBox(height: 15),
              Text('Loading...')
            ],
          ),
        ),
      );
    },
  );
}
