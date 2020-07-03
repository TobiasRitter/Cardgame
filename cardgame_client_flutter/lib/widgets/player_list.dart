import 'package:cardgame_client_flutter/main.dart';
import 'package:flutter/material.dart';

String getRoleString(String roleRaw) {
  switch (roleRaw) {
    case 'Role.king':
      return 'King';
    case 'Role.vizeKing':
      return 'Vize-King';
    case 'Role.vizeArsch':
      return 'Vize-Arsch';
    case 'Role.arsch':
      return 'Arsch';
    case 'Role.neutral':
      return 'Neutral';
    default:
      return null;
  }
}

Widget getPlayerList(
    BuildContext context,
    String ownName,
    String playing,
    Map<dynamic, dynamic> cardCounts,
    Map<dynamic, dynamic> roles,
    bool showCardCounts,
    CrossAxisAlignment crossAxisAlignment) {
  return Column(
    crossAxisAlignment: crossAxisAlignment,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Players:',
          style: captionStyle,
        ),
      ),
      SizedBox(
        width: 200,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: cardCounts.length,
          itemBuilder: (ctxt, index) {
            var name = cardCounts.keys.elementAt(index);
            var cardCount = cardCounts[name];
            var roleString = getRoleString(roles[name]);
            return ListTile(
              trailing: ownName == name ? Icon(Icons.person) : null,
              isThreeLine: roleString != null,
              subtitle: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.subtitle1.copyWith(
                        color: playing == name
                            ? Theme.of(context).accentColor
                            : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w100,
                      ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$cardCount cards left',
                    ),
                    TextSpan(
                      text: roleString == null ? '' : '\n$roleString',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              selected: playing == name,
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
