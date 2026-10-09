import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import '../engine/simon_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'widgets.dart';

const modeNames = ['Solo', 'Endless', 'Score Attack'];
const difficultyNames = ['Chill', 'Classic', 'Turbo'];

/// The Simon table: 4 chunky pads, engine-owned phases, animated playback.
class GameScreen extends StatefulWidget {
  final SimonAudio audio;
  final SimonSettings settings;
  final StoreService store;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final SimonEngine _engine;
  late final SimonThemeDef _theme;
  late final (PadShape, PadFinish) _padSpec;
  bool _statsRecorded = false;
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme = SimonThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    _padSpec = padStyleSpec(widget.settings.padStyle);
    _engine = SimonEngine(
      mode: SimonMode.values[widget.settings.mode],
      difficulty: SimonDifficulty.values[widget.settings.difficulty],
    );
    _engine.onEvent = _onEngineEvent;
    widget.audio.startGameMusic();
    // Small beat before the first round so the screen settles.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _engine.start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    widget.audio.startMenuMusic();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine on interruption; resume re-enters the phase.
    if (state == AppLifecycleState.paused && _engine.playing) {
      _engine.setPaused(true);
    }
  }

  void _onEngineEvent(SimonEvent e, int pad) {
    final a = widget.audio;
    switch (e) {
      case SimonEvent.gameStart:
        a.gameStart();
      case SimonEvent.padLit:
      case SimonEvent.echo:
        a.pad(pad);
      case SimonEvent.roundClear:
        a.roundClear();
      case SimonEvent.wrongPad:
        a.invalid();
      case SimonEvent.lifeLost:
        a.lifeLost();
      case SimonEvent.gameOver:
        a.lose();
        _finishGame();
    }
  }

  Future<void> _finishGame() async {
    if (_statsRecorded) return;
    _statsRecorded = true;
    final newBest = await widget.settings.recordGame(
      modeIndex: _engine.mode.index,
      roundsCompleted: _engine.roundsCompleted,
      score: _engine.finalScore,
    );
    if (!mounted) return;
    // A big run deserves a fanfare — and maybe a rating ask.
    if (_engine.roundsCompleted >= 8) widget.audio.win();
    setState(() => _showGameOver = true);
    if (newBest) {
      // in_app_review is graceful when the app didn't come from Play.
      try {
        if (await InAppReview.instance.isAvailable()) {
          await InAppReview.instance.requestReview();
        }
      } catch (_) {}
    }
  }

  void _pauseGame() {
    if (!_engine.playing || _engine.paused) return;
    widget.audio.click();
    _engine.setPaused(true);
  }

  void _resumeGame() {
    widget.audio.click();
    _engine.setPaused(false);
  }

  void _restartGame() {
    widget.audio.click();
    setState(() {
      _statsRecorded = false;
      _showGameOver = false;
    });
    _engine.setPaused(false);
    _engine.start();
  }

  void _quitToMenu() {
    widget.audio.click();
    _engine.quit();
    Navigator.of(context).pop();
  }

  String _statusText() {
    switch (_engine.phase) {
      case SimonPhase.idle:
        return 'Hit start…';
      case SimonPhase.countdown:
        return 'Get ready… 👀';
      case SimonPhase.showing:
        return 'Watch closely…';
      case SimonPhase.input:
        return 'Your turn! (${_engine.inputIndex}/${_engine.sequence.length})';
      case SimonPhase.roundClear:
        return 'Round survived! 🎉';
      case SimonPhase.gameOver:
        return 'Game over!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return Cabinet(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accent),
            onPressed: _quitToMenu,
          ),
          title: Text(
            '${modeNames[_engine.mode.index]} • ${difficultyNames[_engine.difficulty.index]}',
            style: TextStyle(
                color: t.text, fontWeight: FontWeight.w800, fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            if (_engine.playing && !_engine.paused)
              IconButton(
                icon: Icon(Icons.pause, color: t.accent),
                onPressed: _pauseGame,
              ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _engine,
            builder: (_, _) => Stack(
              children: [
                _table(t),
                if (_engine.paused) _pauseOverlay(t),
                if (_showGameOver &&
                    _engine.phase == SimonPhase.gameOver &&
                    !_engine.paused)
                  _gameOverOverlay(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _table(SimonThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Column(
        children: [
          _hud(t),
          const SizedBox(height: 8),
          Text(
            _statusText(),
            style: TextStyle(
              color: _engine.phase == SimonPhase.gameOver
                  ? const Color(0xFFE08A8A)
                  : t.muted,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (_, i) => ChunkyPad(
                    color: t.pads[i],
                    lit: _engine.litPad == i,
                    wrong: _engine.wrongPad == i,
                    shape: _padSpec.$1,
                    finish: _padSpec.$2,
                    onTap: () => _engine.tapPad(i),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.settings.playerName} is playing',
            style: TextStyle(
                color: t.muted.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _hud(SimonThemeDef t) {
    final chips = <Widget>[
      _chip(t, '🔔 Round ${_engine.round == 0 ? '–' : _engine.round}'),
    ];
    if (_engine.mode == SimonMode.endless) {
      chips.add(_chip(
          t, '❤️ ${_engine.lives}', _engine.lives == 1 ? 'last one!' : null));
    } else if (_engine.mode == SimonMode.scoreAttack) {
      chips.add(_chip(t, '⏱️ ${_engine.timeLeft.ceil()}s'));
      chips.add(_chip(t, '⭐ ${_engine.score}'));
    } else {
      chips.add(_chip(t, '🧠 ${_engine.sequence.length} steps'));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }

  Widget _chip(SimonThemeDef t, String label, [String? extra]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Text(
        extra == null ? label : '$label  •  $extra',
        style: TextStyle(
            color: t.text, fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  Widget _pauseOverlay(SimonThemeDef t) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: t.cabinet,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.accent, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Paused',
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 26)),
              const SizedBox(height: 6),
              Text('The pads are holding their breath…',
                  style: TextStyle(color: t.muted, fontSize: 14)),
              const SizedBox(height: 18),
              ArcadeButton(
                  label: 'Resume',
                  emoji: '▶️',
                  theme: t,
                  primary: true,
                  onTap: _resumeGame),
              const SizedBox(height: 10),
              ArcadeButton(
                  label: 'Restart',
                  emoji: '🔄',
                  theme: t,
                  onTap: _restartGame),
              const SizedBox(height: 10),
              ArcadeButton(
                  label: 'Quit',
                  emoji: '🏠',
                  theme: t,
                  onTap: _quitToMenu),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameOverOverlay(SimonThemeDef t) {
    final rounds = _engine.roundsCompleted;
    final score = _engine.finalScore;
    final isAttack = _engine.mode == SimonMode.scoreAttack;
    final best = switch (_engine.mode) {
      SimonMode.solo => widget.settings.bestSolo,
      SimonMode.endless => widget.settings.bestEndless,
      SimonMode.scoreAttack => widget.settings.bestAttack,
    };
    final isNewBest = isAttack ? score >= best && score > 0 : rounds >= best && rounds > 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: t.cabinet,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.accent, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Game Over!',
                    style: TextStyle(
                        color: t.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 28)),
                if (isNewBest && (rounds > 0 || score > 0)) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: t.accent.withValues(alpha: 0.25),
                      border: Border.all(color: t.accent),
                    ),
                    child: Text('🏆 NEW BEST!',
                        style: TextStyle(
                            color: t.accent,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  isAttack
                      ? '${widget.settings.playerName} scored $score points!'
                      : '${widget.settings.playerName} reached round $rounds!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  isAttack
                      ? 'Best score: $best'
                      : 'Best round: $best',
                  style: TextStyle(color: t.muted, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  _flavor(rounds),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                ArcadeButton(
                    label: 'Play again',
                    emoji: '🔄',
                    theme: t,
                    primary: true,
                    onTap: _restartGame),
                const SizedBox(height: 10),
                ArcadeButton(
                    label: 'Menu',
                    emoji: '🏠',
                    theme: t,
                    onTap: _quitToMenu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _flavor(int rounds) {
    if (rounds >= 10) return 'Memory of an elephant! Absolutely elite. 🐘';
    if (rounds >= 7) return 'Sharp focus! The pads fear you now. ⚡';
    if (rounds >= 4) return 'Nice run! A little rhythm and you\'ll fly. 🎵';
    if (rounds >= 2) return 'Warming up! Your brain is just getting started. 🌱';
    return 'Every master was once a beginner. Go again! 💪';
  }
}
