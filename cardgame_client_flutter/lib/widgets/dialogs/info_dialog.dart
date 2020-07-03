import 'package:flutter/material.dart';

Future showInfoDialog(BuildContext context, String info) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('$info'),
        actions: <Widget>[
          RaisedButton.icon(
            color: Theme.of(context).accentColor,
            label: Text('OK'),
            icon: Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}
