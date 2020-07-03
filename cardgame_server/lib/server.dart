import 'dart:convert';
import 'dart:io';

import 'package:cardgame_server/game.dart';
import 'package:cardgame_server/player.dart';

class Server {
  var clients = <WebSocket>{};
  var game;
  final address = '0.0.0.0';
  final port = 8081;

  void run() {
    game = Game();
    HttpServer.bind(address, port).then((HttpServer server) {
      print('[+]WebSocket listening at -- ws://$address:$port/');
      server.listen((HttpRequest request) {
        WebSocketTransformer.upgrade(request).then((WebSocket socket) {
          addClient(socket);
        }, onError: onError);
      }, onError: onError);
    }, onError: onError);
  }

  void addClient(WebSocket socket) {
    clients.add(socket);
    print('[+]Client added');
    socket.listen(
      (data) => processRequest(socket, data),
      onDone: () => removeClient(socket),
      onError: onError,
      cancelOnError: true,
    );
  }

  void removeClient(WebSocket socket) {
    clients.remove(socket);
    print('[+]Client removed');
    var player = game.players
        .firstWhere((plyr) => plyr.socket == socket, orElse: () => null);
    if (player != null) {
      game.players.remove(player);
      game.endGame(false);
      updatePlayerLeft(player);
      updatePublicData();
      print('[+]${player.name} left');
    }
  }

  void onError(dynamic err) {
    (err) => print('[!]Error -- ${err.toString()}');
  }

  void processRequest(WebSocket socket, dynamic data) {
    print(data);
    try {
      var content = json.decode(data) as Map<String, dynamic>;
      var requestType = content['requestType'];
      print('Request: $content');
      switch (requestType) {
        case 'new_player':
          handleNewPlayer(socket, content);
          break;
        case 'play_cards':
          handlePlayCards(socket, content);
          break;
        case 'send_cards':
          handleSendCards(socket, content);
          break;
        case 'check':
          handleCheck();
          break;
        case 'new_game':
          handleNewGame();
          break;
        default:
          throw ('Unknown requestType: $requestType');
      }
    } catch (e) {
      print('[!]Exception occured: $e.');
      sendResponse(socket, 'error', body: {'message': '$e'});
    }
  }

  void sendResponse(WebSocket socket, String requestType,
      {Map<String, dynamic> body}) {
    if (socket.readyState == WebSocket.open) {
      var message = <String, dynamic>{'requestType': requestType};
      if (body != null) {
        message.addAll(body);
      }
      print('Sending: $message');
      socket.add(json.encode(message));
    }
  }

  void broadcast(String requestType,
      {Map<String, dynamic> body, Set<WebSocket> without}) {
    clients.forEach((socket) {
      if (without == null || !without.contains(socket)) {
        sendResponse(socket, requestType, body: body);
      }
    });
  }

  void handleNewPlayer(WebSocket socket, Map data) {
    if (game.running) {
      throw ('Game is already running');
    }
    var playerName = data['playerName'];
    var player = Player(socket, playerName);
    try {
      game.newPlayer(player);
    } catch (e) {
      updateNewPlayerFailed(socket, e.toString());
    }
    updatePrivateData(socket);
    updatePublicData();
    print('[+]${player.name} joined');
  }

  void handleSendCards(WebSocket socket, Map data) {
    var player = game.players.firstWhere((plyr) => plyr.socket == socket);
    var cards = data['cards'];
    game.sendCards(player, cards);
    clients.forEach((ws) => updatePrivateData(ws));
    updatePublicData();
  }

  void handlePlayCards(WebSocket socket, Map data) {
    var player = game.players.firstWhere((plyr) => plyr.socket == socket);
    var cards = data['cards'];
    if (game.playCards(player, cards)) {
      updateGameFinished();
    }
    updatePrivateData(socket);
    updatePublicData();
  }

  void handleCheck() {
    game.check();
    updatePublicData();
  }

  void handleNewGame() {
    game.newGame();
    clients.forEach((ws) => updatePrivateData(ws));
    updatePublicData();
  }

  void updatePrivateData(WebSocket socket) {
    var player = game.players
        .firstWhere((plyr) => plyr.socket == socket, orElse: () => null);
    if (player != null) {
      sendResponse(socket, 'update_private', body: {
        'name': player.name,
        'sending': player.state.sending,
        'player_cards': player.cards.toList(),
      });
    }
  }

  void updatePublicData() {
    var active = <String, dynamic>{};
    game.players
        .forEach((player) => active.addAll({player.name: player.state.active}));
    var cardCounts = <String, dynamic>{};
    game.players.forEach(
        (player) => cardCounts.addAll({player.name: player.cards.length}));
    var roles = <String, dynamic>{};
    game.players.forEach(
        (player) => roles.addAll({player.name: player.state.role.toString()}));
    broadcast('update_public', body: {
      'card_stack': game.cardStack.toList(),
      'playing': game.playing?.name,
      'stack_owner': game.stackOwner?.name,
      'active': active,
      'card_counts': cardCounts,
      'roles': roles,
      'running': game.running,
    });
  }

  void updateGameFinished() {
    var loser = game.players.firstWhere((player) => player.state.active == true,
        orElse: () => null);
    broadcast('game_finished', body: {
      'loser': loser.name,
    });
  }

  void updatePlayerLeft(Player player) {
    broadcast('player_left', body: {
      'name': player.name,
    });
  }

  void updateNewPlayerFailed(WebSocket socket, String error) {
    sendResponse(socket, 'new_player_failed', body: {
      'message': error,
    });
  }
}
