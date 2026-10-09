import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'widgets.dart';

const _storeUrl =
    'https://play.google.com/store/apps/details?id=com.gameswajiha.simon';

/// Main menu: play, mode + difficulty pickers, best scores, share, Pro.
class MenuScreen extends StatelessWidget {
  final SimonAudio audio;
  final SimonSettings settings;
  final StoreService store;

  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  SimonThemeDef _theme() =>
      SimonThemes.byId(settings.themeId, custom: settings.customTheme);

  void _play(BuildContext context) {
    audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: audio,
          settings: settings,
          store: store,
        ),
      ),
    );
  }

  void _share() {
    audio.click();
    final best = settings.bestSolo;
    Share.share(
      best > 0
          ? 'Can you beat my memory? I reached round $best in Simon! 🧠🔔\n$_storeUrl'
          : 'I\'m playing Simon — the memory arcade! Watch, listen, repeat. 🧠🔔\n$_storeUrl',
      subject: 'Simon — the memory arcade',
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme();
    return Cabinet(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) {
              final theme = _theme();
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    _header(theme),
                    const SizedBox(height: 18),
                    _bestStrip(theme),
                    const SizedBox(height: 18),
                    ArcadeButton(
                      label: 'PLAY',
                      emoji: '▶️',
                      theme: theme,
                      primary: true,
                      width: 280,
                      onTap: () => _play(context),
                    ),
                    SectionTitle('Mode', theme: theme),
                    _modeCards(context, theme),
                    SectionTitle('Difficulty', theme: theme),
                    _difficultyRow(context, theme),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _menuChip(theme, '🎨', 'Themes & Pads', () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                audio: audio,
                                settings: settings,
                                store: store,
                              ),
                            ),
                          );
                        }),
                        _menuChip(theme, '⭐', settings.isPro ? 'PRO ✓' : 'Get PRO', () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProScreen(
                                audio: audio,
                                settings: settings,
                                store: store,
                              ),
                            ),
                          );
                        }),
                        _menuChip(theme, '📣', 'Share', _share),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Watch • Listen • Repeat',
                      style: TextStyle(
                        color: theme.muted.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(SimonThemeDef t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset('assets/simon_logo.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SIMON',
                style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: 5)),
            Text('THE MEMORY ARCADE',
                style: TextStyle(
                    color: t.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 2.5)),
          ],
        ),
      ],
    );
  }

  Widget _bestStrip(SimonThemeDef t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _best(t, '🏆', 'Solo', settings.bestSolo > 0 ? 'Rd ${settings.bestSolo}' : '–'),
          _best(t, '❤️', 'Endless', settings.bestEndless > 0 ? 'Rd ${settings.bestEndless}' : '–'),
          _best(t, '⚡', 'Attack', settings.bestAttack > 0 ? '${settings.bestAttack}' : '–'),
        ],
      ),
    );
  }

  Widget _best(SimonThemeDef t, String emoji, String label, String value) {
    return Column(
      children: [
        Text('$emoji $label',
            style: TextStyle(
                color: t.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: t.text, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _modeCards(BuildContext context, SimonThemeDef t) {
    const modes = [
      ('🧠', 'Solo', 'One mistake ends it. How far can you go?'),
      ('❤️', 'Endless', '3 lives. Mistakes replay the sequence.'),
      ('⚡', 'Score Attack', '90 seconds. Every correct tap scores!'),
    ];
    return Column(
      children: [
        for (int i = 0; i < modes.length; i++)
          _modeCard(context, t, i, modes[i].$1, modes[i].$2, modes[i].$3),
      ],
    );
  }

  void _openPro(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(audio: audio, settings: settings, store: store),
      ),
    );
  }

  Widget _modeCard(BuildContext context, SimonThemeDef t, int i, String emoji,
      String name, String desc) {
    final selected = settings.mode == i;
    final locked = !settings.isPro && i == 2;
    return GestureDetector(
      onTap: () {
        if (locked) {
          audio.invalid();
          _openPro(context);
          return;
        }
        audio.click();
        settings.setMode(i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? t.accent.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.25),
          border: Border.all(
            color: selected ? t.accent : t.accent.withValues(alpha: 0.3),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: TextStyle(
                              color: t.text,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                      if (locked) ...[
                        const SizedBox(width: 8),
                        ProTag(theme: t),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: TextStyle(color: t.muted, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              Text('✓',
                  style: TextStyle(
                      color: t.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Widget _difficultyRow(BuildContext context, SimonThemeDef t) {
    const diffs = [
      ('🐢', 'Chill', 'Gentle pace'),
      ('🎯', 'Classic', 'The real deal'),
      ('🔥', 'Turbo', 'Blazing fast'),
    ];
    return Row(
      children: [
        for (int i = 0; i < diffs.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () {
                final locked = !settings.isPro && i == 2;
                if (locked) {
                  audio.invalid();
                  _openPro(context);
                  return;
                }
                audio.click();
                settings.setDifficulty(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(
                    left: i == 0 ? 0 : 5, right: i == 2 ? 0 : 5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: settings.difficulty == i
                      ? t.accent.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.25),
                  border: Border.all(
                    color: settings.difficulty == i
                        ? t.accent
                        : t.accent.withValues(alpha: 0.3),
                    width: settings.difficulty == i ? 2.5 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(diffs[i].$1,
                        style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 4),
                    Text(diffs[i].$2,
                        style: TextStyle(
                            color: t.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                    Text(diffs[i].$3,
                        style:
                            TextStyle(color: t.muted, fontSize: 10)),
                    if (!settings.isPro && i == 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ProTag(theme: t),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _menuChip(SimonThemeDef t, String emoji, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: t.accent.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Text('$emoji  $label',
            style: TextStyle(
                color: t.text, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
