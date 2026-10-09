import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/simon_themes.dart';

/// Persisted settings + stats for Simon. Survives app restarts.
///
/// Stores: the renameable player profile (ONE JSON string — Android's
/// SharedPreferences stores StringLists as an unordered StringSet, so
/// ordered data must never use setStringList), audio toggles, theme/pad
/// choices (incl. custom theme colors), mode + difficulty, Pro unlock state,
/// and lifetime stats.
class SimonSettings extends ChangeNotifier {
  static const _kMusic = 'simon_music_on';
  static const _kSfx = 'simon_sfx_on';
  static const _kVolume = 'simon_volume';
  static const _kLegacyName = 'simon_player_name'; // legacy plain-string key
  static const _kLegacyProfileJson =
      'simon_profile_json'; // interim JSON key from exemplar work
  /// Order-safe profile storage: a single JSON string. Never setStringList.
  /// (Android SharedPreferences stores StringLists as an unordered StringSet.)
  static const _kProfileJson = 'simon_player_names_json';
  static const _kTheme = 'simon_theme_id';
  static const _kPadStyle = 'simon_pad_style';
  static const _kDifficulty = 'simon_difficulty'; // 0 chill, 1 classic, 2 turbo
  static const _kMode = 'simon_mode'; // 0 solo, 1 endless, 2 score attack
  static const _kIsPro = 'simon_is_pro';
  static const _kGames = 'simon_games_played';
  static const _kBestSolo = 'simon_best_solo';
  static const _kBestEndless = 'simon_best_endless';
  static const _kBestAttack = 'simon_best_attack';
  static const _kTotalSteps = 'simon_total_steps';
  static const _kCustomPrefix = 'simon_custom_';

  static const defaultName = 'Player 1';

  /// Encode the profile as one JSON string (order-preserving, extensible).
  static String encodeProfile(String name) =>
      jsonEncode({'name': name, 'v': 1});

  static String _cleanName(Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultName : s;
  }

  /// Decode the persisted profile; falls back to defaults on missing/corrupt.
  static String decodeProfile(String? raw) {
    if (raw == null) return defaultName;
    try {
      final d = jsonDecode(raw);
      if (d is Map) return _cleanName(d['name']);
    } catch (_) {}
    return defaultName;
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  String themeId = 'classic';
  int padStyle = 0;
  int difficulty = 1; // classic default
  int mode = 0; // solo default
  bool isPro = false;
  int gamesPlayed = 0;
  int bestSolo = 0;
  int bestEndless = 0;
  int bestAttack = 0;
  int totalSteps = 0;

  /// Custom theme colors (ARGB ints). Defaults mirror Classic Arcade.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'bg': 0xFF17100A,
    'panel': 0xFF2A1B0E,
    'accent': 0xFFF2B134,
    'text': 0xFFFFF6E8,
    'pad0': 0xFF2EBD5B,
    'pad1': 0xFFE14B4B,
    'pad2': 0xFFF2B134,
    'pad3': 0xFF3E8EDE,
  };

  /// Builds the user-designed custom theme from stored colors.
  SimonThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final accent = c('accent');
    return SimonThemeDef(
      id: 'custom',
      name: 'My Creation',
      pro: true,
      cabinetDeep: c('bg'),
      cabinet: c('panel'),
      cabinetLight: Color(0xFF453017),
      text: c('text'),
      muted: c('text').withValues(alpha: 0.65),
      accent: accent,
      accentDark: accent.withValues(alpha: 0.6),
      pads: [c('pad0'), c('pad1'), c('pad2'), c('pad3')],
      padNames: const ['One', 'Two', 'Three', 'Four'],
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Profile: prefer the order-safe JSON key. One-time migrations from
    // any older key (interim JSON key, then the legacy plain-string key).
    final profileRaw = p.getString(_kProfileJson);
    final legacyJson = p.getString(_kLegacyProfileJson);
    if (profileRaw != null) {
      playerName = decodeProfile(profileRaw);
    } else if (legacyJson != null) {
      playerName = decodeProfile(legacyJson);
    } else {
      playerName = _cleanName(p.getString(_kLegacyName));
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    padStyle = (p.getInt(_kPadStyle) ?? 0).clamp(0, 7);
    difficulty = (p.getInt(_kDifficulty) ?? 1).clamp(0, 2);
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 2);
    isPro = p.getBool(_kIsPro) ?? false;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestSolo = p.getInt(_kBestSolo) ?? 0;
    bestEndless = p.getInt(_kBestEndless) ?? 0;
    bestAttack = p.getInt(_kBestAttack) ?? 0;
    totalSteps = p.getInt(_kTotalSteps) ?? 0;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileJson, encodeProfile(playerName));
    await p.remove(_kLegacyName); // drop the legacy keys for good
    await p.remove(_kLegacyProfileJson);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kPadStyle, padStyle);
    await p.setInt(_kDifficulty, difficulty);
    await p.setInt(_kMode, mode);
    await p.setBool(_kIsPro, isPro);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBestSolo, bestSolo);
    await p.setInt(_kBestEndless, bestEndless);
    await p.setInt(_kBestAttack, bestAttack);
    await p.setInt(_kTotalSteps, totalSteps);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  /// Called after load and whenever Pro status could have changed.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    // The custom theme creator is a Pro feature ('custom' is not covered by
    // SimonThemes.isProTheme, so it needs an explicit check).
    if (themeId == 'custom' || SimonThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (SimonThemes.isProPadStyle(padStyle)) {
      padStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (mode > 1) {
      mode = 0;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom theme creator) require Pro;
    // silently ignore otherwise (UI shows a lock).
    if (!isPro && (id == 'custom' || SimonThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setPadStyle(int v) async {
    v = v.clamp(0, SimonThemes.padStyleNames.length - 1);
    if (!isPro && SimonThemes.isProPadStyle(v)) return;
    padStyle = v;
    notifyListeners();
    await _save();
  }

  /// 0 chill / 1 classic / 2 turbo (Pro).
  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  /// 0 solo / 1 endless / 2 score attack (Pro).
  Future<void> setMode(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return;
    mode = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished game. [modeIndex] 0 solo / 1 endless / 2 score attack.
  /// Returns true when a new best was set.
  Future<bool> recordGame({
    required int modeIndex,
    required int roundsCompleted,
    required int score,
  }) async {
    gamesPlayed++;
    totalSteps += roundsCompleted;
    var newBest = false;
    switch (modeIndex) {
      case 0:
        if (roundsCompleted > bestSolo) {
          bestSolo = roundsCompleted;
          newBest = true;
        }
      case 1:
        if (roundsCompleted > bestEndless) {
          bestEndless = roundsCompleted;
          newBest = true;
        }
      default:
        if (score > bestAttack) {
          bestAttack = score;
          newBest = true;
        }
    }
    notifyListeners();
    await _save();
    return newBest;
  }
}
