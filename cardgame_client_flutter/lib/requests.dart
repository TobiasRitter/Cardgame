import 'dart:convert';

import 'package:web_socket_channel/html.dart';

void sendRequest(HtmlWebSocketChannel channel, String requestType,
    {Map<String, dynamic> body}) {
  Map<String, dynamic> message = {'requestType': requestType};
  if (body != null) {
    message.addAll(body);
  }
  print('Sending: $message');
  channel.sink.add(json.encode(message));
}

void requestNewPlayer(HtmlWebSocketChannel channel, String playerName) {
  var body = {
    'playerName': playerName,
  };
  sendRequest(channel, 'new_player', body: body);
}

void requestCheck(HtmlWebSocketChannel channel) {
  sendRequest(channel, 'check');
}

void requestNewRound(HtmlWebSocketChannel channel) {
  sendRequest(channel, 'new_game');
}

void requestPlayCards(HtmlWebSocketChannel channel, Set<int> stagedCards) {
  var body = {
    'cards': stagedCards.toList(),
  };

  sendRequest(channel, 'play_cards', body: body);
}

void requestSendCards(HtmlWebSocketChannel channel, Set<int> stagedCards) {
  var body = {
    'cards': stagedCards.toList(),
  };

  sendRequest(channel, 'send_cards', body: body);
}
