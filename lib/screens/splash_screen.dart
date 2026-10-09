import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'menu_screen.dart';

/// Launch splash — a single route with two moments: the WAJIHA company
/// moment, then the game splash (logo + name + animated loading line +
/// "Credits: WAJIHA").
class SplashScreen extends StatefulWidget {
  final SimonAudio audio;
  final SimonSettings settings;
  final StoreService store;
  const SplashScreen(
      {super.key,
      required this.audio,
      required this.settings,
      required this.store});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyPhase = true; // company moment first, then the game splash

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the company moment shows, then start menu music.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _companyPhase = false);
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = SimonThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _companyPhase ? _companyMoment() : _gameSplash(theme),
      ),
    );
  }

  /// The WAJIHA company moment: official winged-W logo, unchanged.
  Widget _companyMoment() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/wajiha_logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 18),
        const Text(
          'WAJIHA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 10,
          ),
        ),
      ],
    );
  }

  /// The game splash: logo + name + animated loading line + credits.
  Widget _gameSplash(SimonThemeDef theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.accent, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                offset: const Offset(0, 10),
                blurRadius: 24,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/simon_logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(height: 22),
        Text(
          'SIMON',
          style: TextStyle(
            color: theme.text,
            fontWeight: FontWeight.w900,
            fontSize: 52,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'THE MEMORY ARCADE',
          style: TextStyle(
            color: theme.accent,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 3.5,
          ),
        ),
        const SizedBox(height: 30),
        // Animated loading line.
        SizedBox(
          width: 220,
          child: AnimatedBuilder(
            animation: _loader,
            builder: (_, _) => Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.black.withValues(alpha: 0.45),
                    border: Border.all(
                        color: theme.accent.withValues(alpha: 0.5)),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _loader.value.clamp(0.02, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: theme.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loader.value < 1 ? 'Warming up the pads…' : 'Ready!',
                  style: TextStyle(
                    color: theme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 44),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Credits: WAJIHA',
              style: TextStyle(
                color: theme.accent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
