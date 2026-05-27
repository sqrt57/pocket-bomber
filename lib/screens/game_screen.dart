import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import '../game/pocket_bomber_game.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: PocketBomberGame());
  }
}
