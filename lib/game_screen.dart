import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Simon — solo memory sequence game.
/// 4 colored pads flash a growing sequence; repeat it to survive.
/// Speed increases every round. One wrong tap ends the run.
class SimonScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const SimonScreen({super.key, required this.players, required this.callbacks});

  @override
  State<SimonScreen> createState() => _SimonScreenState();
}

enum _Phase { idle, watching, input, gameover }

class _SimonScreenState extends State<SimonScreen> {
  static const _padColors = [
    Color(0xFF2EBD5B), // green
    Color(0xFFE14B4B), // red
    Color(0xFFF2B134), // yellow
    Color(0xFF3E8EDE), // blue
  ];

  final _rnd = Random();
  final List<int> _sequence = [];
  int _playerIndex = 0;
  int _round = 0;
  int _lit = -1; // currently lit pad, -1 = none
  int _wrongPad = -1;
  _Phase _phase = _Phase.idle;
  bool _over = false;
  int _gen = 0; // bumped on every (re)start; stale timers check it

  Player get _me => widget.players.first;

  /// Milliseconds per step; gets faster every round, floor at 220ms.
  int get _stepMs => max(220, 640 - _round * 38);

  void _startGame() {
    if (_phase == _Phase.watching || _phase == _Phase.input) return;
    _gen++;
    setState(() {
      _sequence.clear();
      _round = 0;
      _over = false;
      _wrongPad = -1;
    });
    Sfx.click();
    _nextRound();
  }

  void _nextRound() {
    setState(() {
      _round++;
      _sequence.add(_rnd.nextInt(4));
      _phase = _Phase.watching;
      _playerIndex = 0;
    });
    _playSequence();
  }

  Future<void> _playSequence() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted || _over) return;
    for (final pad in _sequence) {
      if (!mounted || _over || _phase != _Phase.watching) return;
      setState(() => _lit = pad);
      Sfx.tap();
      await Future.delayed(Duration(milliseconds: (_stepMs * 0.62).round()));
      if (!mounted) return;
      setState(() => _lit = -1);
      await Future.delayed(Duration(milliseconds: (_stepMs * 0.38).round()));
    }
    if (!mounted || _over) return;
    setState(() => _phase = _Phase.input);
  }

  void _tapPad(int i) {
    if (_phase != _Phase.input || _over) return;
    setState(() => _lit = i);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _lit = -1);
    });
    if (i == _sequence[_playerIndex]) {
      Sfx.move();
      _playerIndex++;
      if (_playerIndex >= _sequence.length) {
        // Round survived!
        _me.score = _round;
        widget.callbacks.refreshHud();
        Sfx.win();
        setState(() => _phase = _Phase.watching);
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted || _over) return;
          _nextRound();
        });
      }
    } else {
      _gameOver(i);
    }
  }

  void _gameOver(int wrongPad) {
    final g = _gen;
    setState(() {
      _phase = _Phase.gameover;
      _wrongPad = wrongPad;
    });
    Sfx.lose();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || _over || g != _gen) return;
      _over = true;
      widget.callbacks.finish(
        headline: 'You reached round $_round! 🔔',
        subline: _round >= 8
            ? 'Memory of an elephant! Absolutely elite. 🐘'
            : _round >= 5
                ? 'Sharp focus! The pads fear you now. ⚡'
                : _round >= 3
                    ? 'Nice run! A little rhythm and you\'ll fly. 🎵'
                    : 'Warm-up done! Your brain is just getting started. 🌱',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip(t, _round == 0 ? 'Ready?' : 'Round $_round',
                  _phase == _Phase.input ? '👆 Your turn' : null),
              if (_phase == _Phase.input || _phase == _Phase.watching)
                _chip(t, '🧠 ${_sequence.length} steps', null),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _statusText(),
            style: TextStyle(
                color: _phase == _Phase.gameover ? t.secondary : t.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14),
                  itemCount: 4,
                  itemBuilder: (_, i) => _pad(i, t),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_phase == _Phase.idle || _phase == _Phase.gameover)
            WajihaButton(
              label: _phase == _Phase.gameover ? 'Play again' : 'Start',
              emoji: _phase == _Phase.gameover ? '🔄' : '▶️',
              onTap: _startGame,
              primary: true,
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _statusText() {
    switch (_phase) {
      case _Phase.idle:
        return 'Hit start and lock in! 🎯';
      case _Phase.watching:
        return 'Watch closely… 👀';
      case _Phase.input:
        return 'Repeat the sequence! ($_playerIndex/${_sequence.length})';
      case _Phase.gameover:
        return 'Oops! Wrong pad. 😅';
    }
  }

  Widget _chip(GameTheme t, String label, String? extra) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: t.radius,
        border: Border.all(color: t.primary.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Text(
        extra == null ? label : '$label  •  $extra',
        style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Widget _pad(int i, GameTheme t) {
    final lit = _lit == i;
    final wrong = _wrongPad == i && _phase == _Phase.gameover;
    final base = wrong ? t.secondary : _padColors[i];
    return GestureDetector(
      onTap: () => _tapPad(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByDouble(lit ? 1.045 : 1.0, lit ? 1.045 : 1.0, 1, 1),
        decoration: BoxDecoration(
          color: lit ? base : base.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: lit ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
            width: 3,
          ),
          boxShadow: lit
              ? [
                  BoxShadow(
                      color: base.withValues(alpha: 0.65),
                      blurRadius: 34,
                      spreadRadius: 4)
                ]
              : [
                  BoxShadow(
                      color: base.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 140),
            opacity: lit ? 1.0 : 0.25,
            child: Text(
              const ['🟢', '🔴', '🟡', '🔵'][i],
              style: const TextStyle(fontSize: 44),
            ),
          ),
        ),
      ),
    );
  }
}
