import 'package:cardgame_server/player.dart';

class Game {
  List<Player> players;
  List<Player> finished;
  Set<int> cardStack;
  Player playing;
  Player stackOwner;
  bool running = false;
  int sending;

  Game()
      : players = <Player>[],
        finished = <Player>[],
        sending = 0,
        cardStack = <int>{};

  void newGame() {
    // reset values
    running = true;
    playing = null;
    stackOwner = null;
    sending = 0;
    cardStack.clear();
    finished.clear();
    // Shuffle players
    players.shuffle();
    players.forEach((player) {
      // Clear player inventories
      player.cards.clear();
      // Set all players to active
      player.state.active = true;
    });
    dealCards();
    if (players.where((plyr) => plyr.state.role == Role.undefined).isEmpty) {
      // let players send cards
      players.forEach((player) {
        if (player.state.role != Role.neutral) {
          player.state.sending = true;
          sending++;
        }
      });
    } else {
      // if a undefined role exists, reset the other roles as well
      players.forEach((player) => player.state.role = Role.undefined);
    }
    if (sending == 0) {
      determineFirstPlayer();
    }
  }

  void endGame(bool regularEnd) {
    stackOwner = null;
    playing = null;
    cardStack.clear();
    running = false;
    if (regularEnd) {
      // distribute roles
      // set all players to neutral
      players.forEach((plyr) => plyr.state.role = Role.neutral);
      var arsch = players.firstWhere((plyr) => plyr.state.active);
      var king = finished.first;
      arsch.state.role = Role.arsch;
      king.state.role = Role.king;
      finished.remove(king);
      if (finished.length >= 2) {
        var vizeArsch = finished.last;
        var vizeKing = finished.first;
        vizeArsch.state.role = Role.vizeArsch;
        vizeKing.state.role = Role.vizeKing;
      }
    }
  }

  void dealCards() {
    var cards = [for (var i = 0; i < 52; i++) i];
    // filter cards
    cards.removeWhere((element) => element < 4 * 4);
    cards.shuffle();
    while (cards.isNotEmpty && cards.length >= players.length) {
      players.forEach((player) {
        player.cards.add(cards.last);
        cards.removeLast();
      });
    }
  }

  void sendCards(Player player, List cards) {
    if (!player.state.sending) {
      throw ('You currently cannot send cards');
    }
    var amountRequired;
    var oppositeRole;
    switch (player.state.role) {
      case Role.arsch:
        amountRequired = 2;
        oppositeRole = Role.king;
        break;
      case Role.vizeArsch:
        amountRequired = 1;
        oppositeRole = Role.vizeKing;
        break;
      case Role.vizeKing:
        amountRequired = 1;
        oppositeRole = Role.vizeArsch;
        break;
      case Role.king:
        amountRequired = 2;
        oppositeRole = Role.arsch;
        break;
      default:
        player.state.sending = false;
        return;
    }
    cards.forEach((card) {
      if (!player.cards.contains(card)) {
        throw ('You do not posses this card: $card');
      }
    });
    if (cards.isEmpty || cards.length != amountRequired) {
      throw ('Invalid amount of cards');
    }
    // send cards
    var oppositePlayer =
        players.firstWhere((plyr) => plyr.state.role == oppositeRole);
    cards.forEach((card) => oppositePlayer.cards.add(card));
    player.cards.removeAll(cards);
    player.state.sending = false;
    sending--;
    if (sending == 0) {
      determineFirstPlayer();
    }
  }

  void determineFirstPlayer() {
    var arsch = players.firstWhere((plyr) => plyr.state.role == Role.arsch,
        orElse: () => null);
    if (arsch != null) {
      playing = arsch;
    } else {
      playing = players.first;
    }
  }

  /// plays the cards and returns true if the game is finished afterwards
  bool playCards(Player player, List cards) {
    if (cards.isEmpty) {
      throw ('Please select the cards you want to play');
    }
    cards.forEach((card) {
      if (!player.cards.contains(card)) {
        throw ('You do not posses this card: $card');
      }
    });
    var color = cards.first % 4;
    var symbol = (cards.first - color) / 4;
    cards.forEach((card) {
      if ((card - (card % 4)) / 4 != symbol) {
        throw ('All cards must have the same symbol');
      }
    });
    if (cards.length == 4) {
      // bomb
      if (cardStack.length == 4) {
        // if previous cards were also a bomb
        var oldColor = cardStack.first % 4;
        var oldSymbol = (cardStack.first - oldColor) / 4;
        if (oldSymbol >= symbol) {
          throw ('Your card(s) must be higher than the previous ones');
        }
      }
    } else {
      if (cardStack.isNotEmpty && cards.length != cardStack.length) {
        throw ('Invalid amount of cards');
      }
      if (cardStack.isNotEmpty) {
        var oldColor = cardStack.first % 4;
        var oldSymbol = (cardStack.first - oldColor) / 4;
        if (oldSymbol >= symbol) {
          throw ('Your card(s) must be higher than the previous ones');
        }
      }
    }
    // Play the cards
    cardStack.clear();
    cards.forEach((card) => cardStack.add(card));
    player.cards.removeAll(cards);
    stackOwner = player;
    nextPlayer();
    if (player.cards.isEmpty) {
      // if player has finished
      player.state.active = false;
      finished.add(player);
      if (finished.length + 1 == players.length) {
        // if only one active player remaining end game
        endGame(true);
        return true;
      }
    }
    return false;
  }

  void newPlayer(Player player) {
    if (!players.contains(player)) {
      players.add(player);
    } else {
      throw ('Player name is already taken');
    }
  }

  void check() {
    if (playing == stackOwner) {
      if (cardStack.isEmpty) {
        throw ('The card stack is already empty');
      }
      cardStack.clear();
    } else {
      nextPlayer();
    }
  }

  void nextPlayer() {
    var oldIndex = players.toList().indexOf(playing);
    var currIndex = (oldIndex + 1) % players.length;
    var currPlyr = players.elementAt(currIndex);
    playing = currPlyr;
    if (!currPlyr.state.active) {
      if (currPlyr == stackOwner) {
        var nextIndex = (currIndex + 1) % players.length;
        var nextPlyr = players.elementAt(nextIndex);
        stackOwner = nextPlyr;
      }
      nextPlayer();
    }
  }
}
