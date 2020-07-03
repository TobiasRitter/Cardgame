import 'dart:async';
import 'dart:convert';

import 'package:cardgame_client_flutter/main.dart';
import 'package:cardgame_client_flutter/requests.dart';
import 'package:cardgame_client_flutter/widgets/card_stages.dart';
import 'package:cardgame_client_flutter/widgets/dialogs/finished_dialog.dart';
import 'package:cardgame_client_flutter/widgets/dialogs/info_dialog.dart';
import 'package:cardgame_client_flutter/widgets/dialogs/name_dialog.dart';
import 'package:cardgame_client_flutter/widgets/player_list.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomePage extends StatefulWidget {
  final String title;
  final WebSocketChannel channel;

  HomePage({Key key, @required this.title, @required this.channel})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name;
  String role;
  String playing;
  String stackOwner;
  var cardCounts = <dynamic, dynamic>{};
  var active = <dynamic, dynamic>{};
  var roles = <dynamic, dynamic>{};
  var playerCards = <int>{};
  var cardStack = <int>{};
  var stagedCards = <int>{};
  var running = false;
  var sending = false;

  void nameDialogCallback(String name) {
    requestNewPlayer(widget.channel, name);
  }

  void moveStage(int card) {
    if (playerCards.contains(card)) {
      setState(() {
        playerCards.remove(card);
        stagedCards.add(card);
      });
    } else if (stagedCards.contains(card)) {
      setState(() {
        stagedCards.remove(card);
        playerCards.add(card);
      });
    }
  }

  Future<void> handleResponses() async {
    await for (var data in widget.channel.stream) {
      var content = json.decode(data) as Map<String, dynamic>;
      var requestType = content['requestType'];
      print('Response: $content');
      switch (requestType) {
        case 'update_public':
          var cardStackList = content['card_stack'];
          var cardStackSet = <int>{};
          for (int item in cardStackList) {
            cardStackSet.add(item);
          }
          setState(() {
            playing = content['playing'];
            stackOwner = content['stack_owner'];
            active = content['active'];
            running = content['running'];
            cardCounts = content['card_counts'];
            roles = content['roles'];
            this.cardStack = cardStackSet;
          });
          break;
        case 'update_private':
          var playerCardsList = content['player_cards'];
          var playerCardsSet = <int>{};
          for (int item in playerCardsList) {
            playerCardsSet.add(item);
          }
          setState(() {
            name = content['name'];
            sending = content['sending'];
            playerCards = playerCardsSet;
            stagedCards = <int>{};
          });
          break;
        case 'game_finished':
          var loser = content['loser'];
          showGameFinishedDialog(context, name, loser);
          break;
        case 'player_left':
          var player = content['name'];
          showInfoDialog(context, '$player left');
          break;
        case 'new_player_failed':
          var error = content['message'];
          showNameDialog(context, nameDialogCallback, error: error);
          break;
        case 'error':
          var err = content['message'];
          print('Server says: $err');
          showInfoDialog(context, '$err');
          break;
        default:
          throw ('Unknown requestType: $requestType');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    handleResponses();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await showNameDialog(context, nameDialogCallback);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return running
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  color: Theme.of(context).brightness == Brightness.light &&
                          playing != name
                      ? Colors.black
                      : null,
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.invert_colors,
                    color: Theme.of(context).brightness == Brightness.light &&
                            playing != name
                        ? Colors.black
                        : null,
                  ),
                  onPressed: () => DynamicTheme.of(context).setBrightness(
                      Theme.of(context).brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark),
                ),
              ],
              backgroundColor: playing == name
                  ? Theme.of(context).accentColor
                  : Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).bottomAppBarColor
                      : null,
            ),
            body: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Scaffold(
                            body: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Card Stack:',
                                    style: captionStyle,
                                  ),
                                ),
                                getCardStage(cardStack, null, false),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Play These Cards:',
                                    style: captionStyle,
                                  ),
                                ),
                                getCardStage(stagedCards, moveStage,
                                    playing == name || sending),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Keep These Cards:',
                                    style: captionStyle,
                                  ),
                                ),
                                getCardStage(playerCards, moveStage,
                                    playing == name || sending),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: FlatButton.icon(
                                        label: Text(playing == name &&
                                                stackOwner == name
                                            ? 'Clear Stack'
                                            : 'Skip Turn'),
                                        icon: Icon(playing == name &&
                                                stackOwner == name
                                            ? Icons.delete
                                            : Icons.fast_forward),
                                        onPressed: playing == name
                                            ? () => requestCheck(widget.channel)
                                            : null,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: RaisedButton.icon(
                                        color: Theme.of(context).accentColor,
                                        textColor: Colors.white,
                                        label: Text(sending
                                            ? 'Send Cards'
                                            : 'Play Cards'),
                                        icon: Icon(
                                            sending ? Icons.send : Icons.done),
                                        onPressed: sending
                                            ? () => requestSendCards(
                                                widget.channel, stagedCards)
                                            : stagedCards != null &&
                                                    playing == name
                                                ? () => requestPlayCards(
                                                    widget.channel, stagedCards)
                                                : null,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: Theme.of(context).bottomAppBarColor,
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: <Widget>[
                              getPlayerList(context, name, playing, cardCounts,
                                  roles, true, CrossAxisAlignment.start),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.invert_colors,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black
                        : null,
                  ),
                  onPressed: () => DynamicTheme.of(context).setBrightness(
                      Theme.of(context).brightness == Brightness.dark
                          ? Brightness.light
                          : Brightness.dark),
                ),
              ],
            ),
            body: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    getPlayerList(context, name, playing, cardCounts, roles,
                        false, CrossAxisAlignment.center),
                    Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: RaisedButton.icon(
                            icon: Icon(Icons.arrow_forward),
                            color: Theme.of(context).accentColor,
                            textColor: Colors.white,
                            label: Text('Let\'s go!'),
                            onPressed: cardCounts == null ||
                                    cardCounts.length < MIN_PLAYER_AMOUNT
                                ? null
                                : () => requestNewRound(widget.channel),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedSwitcher(
                            duration:
                                Duration(milliseconds: ANIMATION_DURATION),
                            child: cardCounts == null ||
                                    cardCounts.length < MIN_PLAYER_AMOUNT
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(Icons.info_outline),
                                      ),
                                      Text(
                                        'At least $MIN_PLAYER_AMOUNT players required',
                                      ),
                                    ],
                                  )
                                : Text(''),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}
