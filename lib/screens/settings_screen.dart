import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';
import 'widgets.dart';

/// Settings: renameable player profile, audio, themes, pad styles, custom
/// theme creator (Pro).
class SettingsScreen extends StatefulWidget {
  final SimonAudio audio;
  final SimonSettings settings;
  final StoreService store;

  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtl;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    // Commit the name on focus loss (e.g. user taps away mid-typing).
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) {
        widget.settings.setPlayerName(_nameCtl.text);
      }
    });
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameCtl.dispose();
    super.dispose();
  }

  SimonThemeDef _theme() => SimonThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme);

  void _openPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final t = _theme();
        return Cabinet(
          theme: t,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: t.accent),
                onPressed: () {
                  widget.audio.click();
                  Navigator.of(context).pop();
                },
              ),
              title: Text('Settings',
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('Player profile', theme: t),
                    _nameRow(t),
                    SectionTitle('Sound', theme: t),
                    _toggleRow(t, '🎵', 'Music', widget.settings.musicOn,
                        (v) {
                      widget.settings.setMusic(v);
                      widget.audio.configure(
                        musicOn: v,
                        sfxOn: widget.settings.sfxOn,
                        volume: widget.settings.volume,
                      );
                      if (v) {
                        widget.audio.click();
                        widget.audio.startMenuMusic();
                      }
                    }),
                    _toggleRow(t, '🔔', 'Sound effects', widget.settings.sfxOn,
                        (v) {
                      widget.settings.setSfx(v);
                      widget.audio.configure(
                        musicOn: widget.settings.musicOn,
                        sfxOn: v,
                        volume: widget.settings.volume,
                      );
                      if (v) widget.audio.click();
                    }),
                    _volumeRow(t),
                    SectionTitle('Cabinet theme', theme: t),
                    _themeGrid(t),
                    SectionTitle('Pad style', theme: t),
                    _padGrid(t),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nameRow(SimonThemeDef t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text('😎', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameCtl,
              focusNode: _nameFocus,
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w700, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Your name',
                hintStyle: TextStyle(color: t.muted),
              ),
              maxLength: 20,
              // Save on EVERY keystroke — never rely on keyboard-done alone.
              onChanged: (v) {
                widget.settings.setPlayerName(v);
              },
              onSubmitted: (v) {
                widget.audio.click();
                widget.settings.setPlayerName(v);
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          TextButton(
            onPressed: () {
              widget.audio.click();
              widget.settings.setPlayerName(_nameCtl.text);
              FocusScope.of(context).unfocus();
            },
            child: Text('Save',
                style: TextStyle(
                    color: t.accent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(SimonThemeDef t, String emoji, String label, bool value,
      ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
          Switch(
            value: value,
            activeThumbColor: t.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _volumeRow(SimonThemeDef t) {
    return Row(
      children: [
        Text('🔊', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Slider(
            value: widget.settings.volume,
            activeColor: t.accent,
            inactiveColor: t.cabinetLight,
            onChanged: (v) {
              widget.settings.setVolume(v);
              widget.audio.configure(
                musicOn: widget.settings.musicOn,
                sfxOn: widget.settings.sfxOn,
                volume: v,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _themeGrid(SimonThemeDef t) {
    final themes = [...SimonThemes.all];
    final isPro = widget.settings.isPro;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemCount: themes.length + 1, // + custom creator tile
      itemBuilder: (_, idx) {
        if (idx == themes.length) return _customTile(t, isPro);
        final th = themes[idx];
        final selected = widget.settings.themeId == th.id;
        final locked = !isPro && th.pro;
        return GestureDetector(
          onTap: () {
            if (locked) {
              widget.audio.invalid();
              _openPro();
              return;
            }
            widget.audio.click();
            widget.settings.setTheme(th.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: th.cabinet,
              border: Border.all(
                color: selected ? t.accent : t.accent.withValues(alpha: 0.25),
                width: selected ? 2.5 : 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mini 2x2 pad preview.
                SizedBox(
                  width: 52,
                  height: 52,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                    ),
                    itemCount: 4,
                    itemBuilder: (_, i) => Container(
                      decoration: BoxDecoration(
                        color: th.pads[i],
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            offset: const Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(th.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: th.text,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
                if (locked)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: ProTag(theme: t),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _customTile(SimonThemeDef t, bool isPro) {
    final selected = widget.settings.themeId == 'custom';
    return GestureDetector(
      onTap: () {
        if (!isPro) {
          widget.audio.invalid();
          _openPro();
          return;
        }
        widget.audio.click();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomThemeScreen(
              audio: widget.audio,
              settings: widget.settings,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected ? t.accent : t.accent.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🎨', style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 6),
            Text('My Creation',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: t.text, fontSize: 10, fontWeight: FontWeight.w700)),
            if (!isPro)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: ProTag(theme: t),
              ),
          ],
        ),
      ),
    );
  }

  Widget _padGrid(SimonThemeDef t) {
    final isPro = widget.settings.isPro;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: SimonThemes.padStyleNames.length,
      itemBuilder: (_, i) {
        final locked = !isPro && SimonThemes.isProPadStyle(i);
        final selected = widget.settings.padStyle == i;
        final (shape, finish) = padStyleSpec(i);
        return GestureDetector(
          onTap: () {
            if (locked) {
              widget.audio.invalid();
              _openPro();
              return;
            }
            widget.audio.click();
            widget.settings.setPadStyle(i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withValues(alpha: 0.25),
              border: Border.all(
                color: selected ? t.accent : t.accent.withValues(alpha: 0.25),
                width: selected ? 2.5 : 1.2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ChunkyPad(
                    color: t.pads[0],
                    lit: false,
                    wrong: false,
                    shape: shape,
                    finish: finish,
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 4),
                Text(SimonThemes.padStyleNames[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
                if (locked)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ProTag(theme: t),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
