import 'package:cardgame_client_flutter/widgets/home_page.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/material.dart';

const MIN_PLAYER_AMOUNT = 2;
const ANIMATION_DURATION = 300;
const captionStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w300,
);

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final title = 'CardGame';
    var myLightTheme = ThemeData(
      brightness: Brightness.light,
      accentColor: Colors.blueAccent,
      cursorColor: Colors.blueAccent,
      textSelectionColor: Colors.blueAccent,
      fontFamily: 'OpenSans',
    );
    var myDarkTheme = ThemeData(
      brightness: Brightness.dark,
      accentColor: Colors.blueAccent,
      cursorColor: Colors.blueAccent,
      textSelectionColor: Colors.blueAccent,
      fontFamily: 'OpenSans',
    );
    var channel = HtmlWebSocketChannel.connect('ws://25.139.139.160:8081/');
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) =>
          brightness == Brightness.light ? myLightTheme : myDarkTheme,
      themedWidgetBuilder: (context, theme) {
        return MaterialApp(
          title: title,
          theme: theme,
          home: HomePage(
            title: title,
            channel: channel,
          ),
        );
      },
    );
  }
}
