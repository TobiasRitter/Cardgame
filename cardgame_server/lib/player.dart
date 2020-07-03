import 'dart:io';

import 'package:equatable/equatable.dart';

enum Role {
  arsch,
  vizeArsch,
  king,
  vizeKing,
  undefined,
  neutral,
}

class Player extends Equatable {
  final WebSocket socket;
  final String name;
  final Set<int> cards;
  final PlayerState state;

  Player(this.socket, this.name)
      : cards = <int>{},
        state = PlayerState();

  @override
  List<Object> get props => [name];
}

class PlayerState {
  Role role;
  bool active = false;
  bool sending = false;

  PlayerState() : role = Role.undefined;
}
