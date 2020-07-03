import 'package:flutter/material.dart';

Future showGameFinishedDialog(
    BuildContext context, String ownName, String loser) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('The game is over!'),
        content: Text(ownName == loser ? 'You lost!' : 'The loser is: $loser'),
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
