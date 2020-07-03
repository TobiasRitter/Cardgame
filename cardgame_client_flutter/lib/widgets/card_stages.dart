import 'package:flutter/material.dart';

Widget getCardStage(Set<int> cardSet, Function(int) onPressed, bool playable) {
  var cards = cardSet.toList();
  cards.sort();
  return Expanded(
    child: cards != null && cards.isNotEmpty
        ? ListView(
            children: <Widget>[
              Wrap(
                  alignment: WrapAlignment.center,
                  children: cards
                      .map((card) => PlayingCard(
                            card: card,
                            playable: playable,
                            onPressed: onPressed,
                          ))
                      .toList()),
            ],
          )
        : Container(),
  );
}

class PlayingCard extends StatelessWidget {
  final int card;
  final bool playable;
  final Function(int) onPressed;
  int get color => card % 4;
  int get symbolInt => (card - color) / 4 as int;
  String get iconPath {
    switch (color) {
      case 0:
        return 'res/img/spades.png';
      case 1:
        return 'res/img/hearts.png';
      case 2:
        return 'res/img/clubs.png';
      default:
        return 'res/img/diamonds.png';
    }
  }

  String get symbol {
    switch (symbolInt) {
      case 12:
        return 'A';
      case 11:
        return '10';
      case 10:
        return 'K';
      case 9:
        return 'Q';
      case 8:
        return 'J';
      default:
        return (symbolInt + 2).toString();
    }
  }

  const PlayingCard({
    Key key,
    @required this.card,
    @required this.playable,
    @required this.onPressed,
  })  : assert(card != null),
        assert(playable != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => playable ? onPressed(card) : null,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 30,
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Image.asset(iconPath),
                  Text(
                    symbol,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
