import 'dart:io';

import 'package:cardgame_server/server.dart';

var game;
Set<WebSocket> sockets;

void main() {
  var server = Server();
  server.run();
}
