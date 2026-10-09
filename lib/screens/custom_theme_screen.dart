import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'widgets.dart';

/// Custom theme creator (Pro): pick the cabinet colors and the 4 pad colors.
class CustomThemeScreen extends StatelessWidget {
  final SimonAudio audio;
  final SimonSettings settings;

  const CustomThemeScreen({
    super.key,
    required this.audio,
    required this.settings,
  });

  SimonThemeDef _theme() =>
      SimonThemes.byId(settings.themeId, custom: settings.customTheme);

  static const _swatches = [
    0xFF2EBD5B, 0xFFE14B4B, 0xFFF2B134, 0xFF3E8EDE,
    0xFF9B59B6, 0xFF1ABC9C, 0xFFE67E22, 0xFFEC407A,
    0xFF00BCD4, 0xFF8BC34A, 0xFFFFC107, 0xFF795548,
    0xFF607D8B, 0xFFF5F5F5, 0xFF212121, 0xFFFF5722,
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
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
                  audio.click();
                  Navigator.of(context).pop();
                },
              ),
              title: Text('My Creation',
                  style: TextStyle(
                      color: t.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 20)),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: () {
                    audio.click();
                    settings.resetCustomColors();
                  },
                  child: Text('Reset',
                      style: TextStyle(
                          color: t.accent, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview of the 4 pads.
                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: 4,
                          itemBuilder: (_, i) {
                            final (shape, finish) =
                                padStyleSpec(settings.padStyle);
                            return ChunkyPad(
                              color: settings.customTheme.pads[i],
                              lit: false,
                              wrong: false,
                              shape: shape,
                              finish: finish,
                              onTap: () {},
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: ArcadeButton(
                        label: 'Use this theme',
                        emoji: '🎨',
                        theme: t,
                        primary: true,
                        width: 240,
                        onTap: () {
                          audio.click();
                          settings.setTheme('custom');
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    for (final e in _fields.entries) ...[
                      SectionTitle(e.key, theme: t),
                      _swatchRow(t, e.value),
                    ],
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

  static const _fields = {
    'Cabinet background': 'bg',
    'Cabinet panel': 'panel',
    'Accent': 'accent',
    'Text': 'text',
    'Pad 1': 'pad0',
    'Pad 2': 'pad1',
    'Pad 3': 'pad2',
    'Pad 4': 'pad3',
  };

  Widget _swatchRow(SimonThemeDef t, String key) {
    final current = settings.customColors[key] ?? 0xFF000000;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final argb in _swatches)
          GestureDetector(
            onTap: () {
              audio.click();
              settings.setCustomColor(key, argb);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(argb),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: current == argb ? t.text : Colors.black45,
                  width: current == argb ? 3 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
