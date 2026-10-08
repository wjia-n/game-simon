import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const SimonApp());

class SimonApp extends StatelessWidget {
  const SimonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.zenStone,
      title: 'Simon',
      tagline: 'Watch, listen, repeat! How long a light sequence can your brain hold? 🔔',
      emoji: '🔔',
      slug: 'simon',
      howToPlay:
          '• Watch the pads light up and memorize the sequence.\n• Tap the pads in the SAME order to survive the round.\n• Each round adds one more step — and the pace gets faster! ⚡\n• One wrong tap and it\'s game over. Trust your memory! 🧠',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => SimonScreen(players: players, callbacks: cb),
    );
  }
}
