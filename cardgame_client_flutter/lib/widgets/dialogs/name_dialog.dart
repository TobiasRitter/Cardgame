import 'package:flutter/material.dart';

Future showNameDialog(BuildContext context, Function(String) callback,
    {String error}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return NameDialog(callback, error);
    },
  );
}

class NameDialog extends StatefulWidget {
  final Function(String) callback;
  final error;

  NameDialog(this.callback, this.error);

  @override
  _NameDialogState createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final TextEditingController controller = TextEditingController();
  bool nameValid = false;

  @override
  void initState() {
    super.initState();
    controller.addListener(
        () => setState(() => nameValid = controller.text.isNotEmpty));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter your name'),
      content: TextField(
        decoration: InputDecoration(
            labelText: widget.error != null ? widget.error : null),
        controller: controller,
      ),
      actions: <Widget>[
        RaisedButton.icon(
          color: Theme.of(context).accentColor,
          label: Text('OK'),
          icon: Icon(Icons.check),
          onPressed: nameValid
              ? () {
                  widget.callback(controller.text);
                  Navigator.of(context).pop();
                }
              : null,
        ),
      ],
    );
  }
}
