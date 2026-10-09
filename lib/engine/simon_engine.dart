import 'dart:async';
import 'dart:math';

/// Phases owned entirely by the engine. The UI only renders.
enum SimonPhase {
  idle, // on the bench, before a game starts
  countdown, // "Get ready…"
  showing, // engine is flashing the sequence
  input, // player is repeating the sequence
  roundClear, // celebrating a survived round
  gameOver, // terminal: stats recorded, UI shows results
}

/// Engine events the UI wires to audio / haptics.
enum SimonEvent {
  gameStart,
  padLit, // sequence playback: [pad] lit + its tone
  echo, // correct player tap: [pad] echo + its tone
  roundClear,
  wrongPad,
  lifeLost,
  gameOver,
}

/// Modes: Solo (classic survival), Endless (3 lives), Score Attack (90s).
enum SimonMode { solo, endless, scoreAttack }

/// Difficulty tiers: Chill (gentle), Classic (standard), Turbo (fast, Pro).
enum SimonDifficulty { chill, classic, turbo }

/// The Simon game engine: deterministic rules, state, sequence playback.
/// UI-agnostic — the UI listens (ChangeNotifier) and renders only.
///
/// Stuck states are impossible by construction:
/// - The engine owns every phase transition on its own timers.
/// - A watchdog ([_watchdog]) re-arms any phase found without a live timer.
/// - [setPaused] freezes timers; resume re-enters the current phase cleanly.
class SimonEngine extends ChangeNotifier {
  final SimonMode mode;
  final SimonDifficulty difficulty;

  /// Engine → UI audio hook: (event, padIndex).
  void Function(SimonEvent, int)? onEvent;

  final List<int> sequence = [];

  SimonPhase phase = SimonPhase.idle;
  int litPad = -1; // currently lit pad, -1 = none
  int wrongPad = -1; // pad that ended the run (flash red), -1 = none
  int inputIndex = 0; // how many of the current sequence the player got right
  int round = 0; // 1-based: == sequence.length while playing
  int score = 0; // solo/endless: rounds completed; attack: correct taps
  int lives = 3; // endless mode only
  double timeLeft = 90; // score attack only (seconds)

  /// Result for the UI when [phase] reaches gameOver.
  int roundsCompleted = 0;
  int finalScore = 0;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _echoTimer; // tap-echo light timer (never touches _timer)
  Timer? _tickTimer; // score-attack clock
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  // Sequence-playback cursor (for watchdog resume).
  int _showIdx = 0;
  bool _showLitOn = false;

  static const _attackDuration = 90.0;

  // --- difficulty params: start ms/step, ms faster per round, floor --------
  int get _startMs => [800, 640, 480][difficulty.index];
  int get _decrement => [25, 38, 34][difficulty.index];
  int get _floor => [340, 220, 150][difficulty.index];

  /// Milliseconds per step; gets faster every round, floored per difficulty.
  int get stepMs => max(_floor, _startMs - (round - 1) * _decrement);
  int get _onMs => (stepMs * 0.62).round();
  int get _offMs => (stepMs * 0.38).round();

  bool get playing =>
      phase != SimonPhase.idle && phase != SimonPhase.gameOver;
  bool get acceptingInput => phase == SimonPhase.input && !paused;

  SimonEngine({
    required this.mode,
    required this.difficulty,
    this.onEvent,
  }) {
    _watchdog =
        Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _echoTimer?.cancel();
    _tickTimer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _emit(SimonEvent e, [int pad = -1]) => onEvent?.call(e, pad);

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze all timers (phase timer, echo light, attack clock).
  /// Resume re-enters the current phase via the watchdog path.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
      _echoTimer?.cancel();
      _echoTimer = null;
      _tickTimer?.cancel();
      _tickTimer = null;
      if (litPad != -1 && phase == SimonPhase.input) {
        litPad = -1; // clear any half-finished echo
      }
    } else {
      _recover(); // re-arm whatever phase we froze
      if (mode == SimonMode.scoreAttack && playing) _startTick();
    }
    notifyListeners();
  }

  /// Watchdog: if any engine-owned phase ever loses its timer, re-arm it.
  /// This makes stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused) return;
    if (_timer != null) return; // a live timer owns the phase — leave it
    switch (phase) {
      case SimonPhase.countdown:
        _arm(const Duration(milliseconds: 900), _beginRound);
      case SimonPhase.showing:
        // Resume the playback cursor exactly where it stopped.
        if (_showLitOn) {
          _arm(Duration(milliseconds: _onMs), _showOff);
        } else {
          _arm(Duration(milliseconds: _offMs), _showNext);
        }
      case SimonPhase.roundClear:
        _arm(const Duration(milliseconds: 1100), _beginRound);
      case SimonPhase.idle:
      case SimonPhase.input:
      case SimonPhase.gameOver:
        break; // human-driven or terminal — nothing to recover
    }
  }

  // ------------------------------------------------------------- game flow
  void start() {
    sequence.clear();
    round = 0;
    score = 0;
    inputIndex = 0;
    litPad = -1;
    wrongPad = -1;
    lives = 3;
    timeLeft = _attackDuration;
    roundsCompleted = 0;
    finalScore = 0;
    phase = SimonPhase.countdown;
    _emit(SimonEvent.gameStart);
    notifyListeners();
    _arm(const Duration(milliseconds: 1300), _beginRound);
  }

  /// Back to the bench (quit to menu). Cancels everything.
  void quit() {
    _timer?.cancel();
    _echoTimer?.cancel();
    _tickTimer?.cancel();
    phase = SimonPhase.idle;
    litPad = -1;
    wrongPad = -1;
    notifyListeners();
  }

  void _beginRound() {
    if (_disposed || paused || phase == SimonPhase.gameOver) return;
    if (phase != SimonPhase.countdown && phase != SimonPhase.roundClear) {
      return; // stale timer — only these phases may start a round
    }
    round++;
    sequence.add(_rand.nextInt(4));
    phase = SimonPhase.showing;
    _showIdx = 0;
    _showLitOn = false;
    inputIndex = 0;
    wrongPad = -1;
    notifyListeners();
    _arm(const Duration(milliseconds: 500), _showNext); // lead-in beat
  }

  void _showNext() {
    if (phase != SimonPhase.showing) return; // stale timer
    if (_showIdx >= sequence.length) {
      _toInput();
      return;
    }
    final pad = sequence[_showIdx];
    litPad = pad;
    _showLitOn = true;
    _emit(SimonEvent.padLit, pad);
    notifyListeners();
    _arm(Duration(milliseconds: _onMs), _showOff);
  }

  void _showOff() {
    if (phase != SimonPhase.showing) return; // stale timer
    litPad = -1;
    _showLitOn = false;
    _showIdx++;
    notifyListeners();
    _arm(Duration(milliseconds: _offMs), _showNext);
  }

  void _toInput() {
    if (phase != SimonPhase.showing) return;
    litPad = -1;
    phase = SimonPhase.input;
    inputIndex = 0;
    notifyListeners();
  }

  /// Player taps a pad. Taps outside the input phase are illegal moves and
  /// are ignored elegantly (RULES.md §5).
  void tapPad(int i) {
    if (!acceptingInput) return;
    if (i < 0 || i > 3) return;
    litPad = i;
    notifyListeners();
    // Echo light clears on its own timer so it can never desync the phase.
    _echoTimer?.cancel();
    _echoTimer = Timer(const Duration(milliseconds: 180), () {
      _echoTimer = null;
      if (!_disposed && phase == SimonPhase.input && litPad == i) {
        litPad = -1;
        notifyListeners();
      }
    });
    if (i == sequence[inputIndex]) {
      _emit(SimonEvent.echo, i);
      inputIndex++;
      if (mode == SimonMode.scoreAttack) {
        score++; // every correct tap counts
      }
      if (inputIndex >= sequence.length) {
        _roundClear();
      }
    } else {
      _wrong(i);
    }
  }

  void _roundClear() {
    phase = SimonPhase.roundClear;
    litPad = -1;
    roundsCompleted = round;
    if (mode != SimonMode.scoreAttack) score = round;
    _emit(SimonEvent.roundClear);
    notifyListeners();
    _arm(const Duration(milliseconds: 1100), _beginRound);
  }

  void _wrong(int pad) {
    litPad = -1;
    wrongPad = pad;
    notifyListeners();
    if (mode == SimonMode.endless) {
      lives--;
      if (lives <= 0) {
        _emit(SimonEvent.wrongPad, pad);
        _gameOver();
      } else {
        _emit(SimonEvent.lifeLost, pad);
        // Replay the same sequence — no new step added.
        phase = SimonPhase.showing;
        _showIdx = 0;
        _showLitOn = false;
        inputIndex = 0;
        notifyListeners();
        _arm(const Duration(milliseconds: 1200), _showNext);
      }
    } else if (mode == SimonMode.scoreAttack) {
      // Wrong tap costs 5 seconds; the clock keeps running.
      timeLeft = max(0.0, timeLeft - 5);
      _emit(SimonEvent.wrongPad, pad);
      inputIndex = 0; // restart the current sequence attempt
      notifyListeners();
      if (timeLeft <= 0) _gameOver();
    } else {
      _emit(SimonEvent.wrongPad, pad);
      _gameOver();
    }
  }

  void _gameOver() {
    if (phase == SimonPhase.gameOver) return;
    phase = SimonPhase.gameOver;
    litPad = -1;
    finalScore = score;
    _timer?.cancel();
    _timer = null;
    _echoTimer?.cancel();
    _echoTimer = null;
    _tickTimer?.cancel();
    _tickTimer = null;
    _emit(SimonEvent.gameOver);
    notifyListeners();
  }

  // ------------------------------------------------- score-attack clock
  void _startTick() {
    _tickTimer?.cancel();
    if (mode != SimonMode.scoreAttack || _disposed || paused) return;
    _tickTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_disposed || paused || !playing) {
        _tickTimer?.cancel();
        _tickTimer = null;
        return;
      }
      timeLeft = max(0.0, timeLeft - 0.25);
      if (timeLeft <= 0) {
        _gameOver();
      } else {
        notifyListeners();
      }
    });
  }

  @override
  void notifyListeners() {
    // Keep the attack clock alive for the whole game (except when paused).
    if (mode == SimonMode.scoreAttack &&
        playing &&
        !paused &&
        !_disposed &&
        _tickTimer == null &&
        phase != SimonPhase.gameOver) {
      _startTick();
    }
    super.notifyListeners();
  }
}
