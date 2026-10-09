import 'package:flutter/material.dart';

/// Art direction: "Chunky Arcade" — big physical push-buttons on a warm
/// arcade cabinet. Realistic depth: beveled pads, drop shadows, inner
/// highlights. No neon, no cyberpunk, no AI-dashboard looks.
///
/// 12 built-in themes: the first 4 are FREE, the rest are PRO.
/// A user-built custom theme (Pro) is available via [customTheme].
class SimonThemeDef {
  final String id;
  final String name;
  final bool pro;
  final Color cabinetDeep; // page background
  final Color cabinet; // panel background
  final Color cabinetLight; // raised panel edge
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentDark;
  final List<Color> pads; // the 4 chunky pad colors
  final List<String> padNames;

  const SimonThemeDef({
    required this.id,
    required this.name,
    required this.pro,
    required this.cabinetDeep,
    required this.cabinet,
    required this.cabinetLight,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentDark,
    required this.pads,
    required this.padNames,
  });
}

class SimonThemes {
  /// First 4 are FREE; the rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'candy',
    'ocean',
    'sunset',
  ];

  static const List<SimonThemeDef> all = [
    SimonThemeDef(
      id: 'classic',
      name: 'Classic Arcade',
      pro: false,
      cabinetDeep: Color(0xFF17100A),
      cabinet: Color(0xFF2A1B0E),
      cabinetLight: Color(0xFF453017),
      text: Color(0xFFFFF6E8),
      muted: Color(0xFFC9AE8B),
      accent: Color(0xFFF2B134),
      accentDark: Color(0xFFB97A1B),
      pads: [
        Color(0xFF2EBD5B),
        Color(0xFFE14B4B),
        Color(0xFFF2B134),
        Color(0xFF3E8EDE),
      ],
      padNames: ['Green', 'Red', 'Yellow', 'Blue'],
    ),
    SimonThemeDef(
      id: 'candy',
      name: 'Candy Shop',
      pro: false,
      cabinetDeep: Color(0xFF241014),
      cabinet: Color(0xFF3A1B26),
      cabinetLight: Color(0xFF5C2B40),
      text: Color(0xFFFFF0F4),
      muted: Color(0xFFDBA9BC),
      accent: Color(0xFFFF8FB3),
      accentDark: Color(0xFFC2557E),
      pads: [
        Color(0xFF4ADE80),
        Color(0xFFF87171),
        Color(0xFFFFD166),
        Color(0xFF7DD3FC),
      ],
      padNames: ['Mint', 'Cherry', 'Lemon', 'Berry'],
    ),
    SimonThemeDef(
      id: 'ocean',
      name: 'Ocean Deep',
      pro: false,
      cabinetDeep: Color(0xFF081820),
      cabinet: Color(0xFF0F2B38),
      cabinetLight: Color(0xFF1D4457),
      text: Color(0xFFEFFBFF),
      muted: Color(0xFF93BDCB),
      accent: Color(0xFF38BDF8),
      accentDark: Color(0xFF1D7FB8),
      pads: [
        Color(0xFF34D399),
        Color(0xFFF87171),
        Color(0xFFFBBF24),
        Color(0xFF38BDF8),
      ],
      padNames: ['Seafoam', 'Coral', 'Sand', 'Wave'],
    ),
    SimonThemeDef(
      id: 'sunset',
      name: 'Sunset Diner',
      pro: false,
      cabinetDeep: Color(0xFF1F0F08),
      cabinet: Color(0xFF331A0E),
      cabinetLight: Color(0xFF522A17),
      text: Color(0xFFFFF3E6),
      muted: Color(0xFFD3AC85),
      accent: Color(0xFFFF9E4A),
      accentDark: Color(0xFFC25E1B),
      pads: [
        Color(0xFF65A30D),
        Color(0xFFEF4444),
        Color(0xFFFFC53D),
        Color(0xFF0EA5E9),
      ],
      padNames: ['Lime', 'Ketchup', 'Mustard', 'Soda'],
    ),
    SimonThemeDef(
      id: 'forest',
      name: 'Forest Lodge',
      pro: true,
      cabinetDeep: Color(0xFF0E160C),
      cabinet: Color(0xFF1A2615),
      cabinetLight: Color(0xFF2C4023),
      text: Color(0xFFF2F8EC),
      muted: Color(0xFFA9BC9A),
      accent: Color(0xFFA3B86B),
      accentDark: Color(0xFF6E8440),
      pads: [
        Color(0xFF4CAF50),
        Color(0xFFD9534F),
        Color(0xFFE8C547),
        Color(0xFF4D96FF),
      ],
      padNames: ['Moss', 'Rowan', 'Honey', 'Stream'],
    ),
    SimonThemeDef(
      id: 'desert',
      name: 'Desert Oasis',
      pro: true,
      cabinetDeep: Color(0xFF1E140A),
      cabinet: Color(0xFF33250F),
      cabinetLight: Color(0xFF543C1C),
      text: Color(0xFFFFF6E3),
      muted: Color(0xFFD2B585),
      accent: Color(0xFFE0A458),
      accentDark: Color(0xFFA9732F),
      pads: [
        Color(0xFF7FB069),
        Color(0xFFC1666B),
        Color(0xFFF4D35E),
        Color(0xFF5C9CE6),
      ],
      padNames: ['Cactus', 'Clay', 'Dune', 'Spring'],
    ),
    SimonThemeDef(
      id: 'berry',
      name: 'Berry Parlor',
      pro: true,
      cabinetDeep: Color(0xFF180A12),
      cabinet: Color(0xFF2A1220),
      cabinetLight: Color(0xFF462034),
      text: Color(0xFFFFEEF4),
      muted: Color(0xFFD2A3B8),
      accent: Color(0xFFE56B9C),
      accentDark: Color(0xFFA83E6B),
      pads: [
        Color(0xFF66BB6A),
        Color(0xFFE53935),
        Color(0xFFFFD54F),
        Color(0xFFBA68C8),
      ],
      padNames: ['Kiwi', 'Raspberry', 'Custard', 'Plum'],
    ),
    SimonThemeDef(
      id: 'arctic',
      name: 'Arctic Hut',
      pro: true,
      cabinetDeep: Color(0xFF0B1418),
      cabinet: Color(0xFF16242B),
      cabinetLight: Color(0xFF28404C),
      text: Color(0xFFEFF7FA),
      muted: Color(0xFF9DB8C2),
      accent: Color(0xFF7FD1D8),
      accentDark: Color(0xFF4A939B),
      pads: [
        Color(0xFF4ADE80),
        Color(0xFFFF6B6B),
        Color(0xFFFFE066),
        Color(0xFF4CC9F0),
      ],
      padNames: ['Pine', 'Aurora', 'Lantern', 'Glacier'],
    ),
    SimonThemeDef(
      id: 'ember',
      name: 'Ember Hearth',
      pro: true,
      cabinetDeep: Color(0xFF190C06),
      cabinet: Color(0xFF2B160B),
      cabinetLight: Color(0xFF482514),
      text: Color(0xFFFFF1E4),
      muted: Color(0xFFD2A583),
      accent: Color(0xFFFF7B3D),
      accentDark: Color(0xFFB84F1F),
      pads: [
        Color(0xFF8BC34A),
        Color(0xFFFF5722),
        Color(0xFFFFC107),
        Color(0xFF03A9F4),
      ],
      padNames: ['Sprout', 'Ember', 'Flame', 'Smoke'],
    ),
    SimonThemeDef(
      id: 'royal',
      name: 'Royal Plum',
      pro: true,
      cabinetDeep: Color(0xFF120A1A),
      cabinet: Color(0xFF211130),
      cabinetLight: Color(0xFF38204E),
      text: Color(0xFFF6EEFF),
      muted: Color(0xFFBBA3D4),
      accent: Color(0xFFC084FC),
      accentDark: Color(0xFF8B5AAD),
      pads: [
        Color(0xFF6BCB77),
        Color(0xFFFF6B6B),
        Color(0xFFFFD93D),
        Color(0xFF6BCBFF),
      ],
      padNames: ['Jade', 'Ruby', 'Crown', 'Sapphire'],
    ),
    SimonThemeDef(
      id: 'slate',
      name: 'Slate Workshop',
      pro: true,
      cabinetDeep: Color(0xFF101114),
      cabinet: Color(0xFF1C1E24),
      cabinetLight: Color(0xFF30343E),
      text: Color(0xFFF4F5F7),
      muted: Color(0xFFA9AFBC),
      accent: Color(0xFFF2A65A),
      accentDark: Color(0xFFB06E2E),
      pads: [
        Color(0xFF58B368),
        Color(0xFFE4572E),
        Color(0xFFF3A712),
        Color(0xFF3D8BFD),
      ],
      padNames: ['Copper', 'Rust', 'Brass', 'Steel'],
    ),
    SimonThemeDef(
      id: 'meadow',
      name: 'Meadow Fair',
      pro: true,
      cabinetDeep: Color(0xFF0F170E),
      cabinet: Color(0xFF1B281A),
      cabinetLight: Color(0xFF2E452C),
      text: Color(0xFFF3F9EE),
      muted: Color(0xFFA9BFA4),
      accent: Color(0xFFB7D77A),
      accentDark: Color(0xFF7FA04A),
      pads: [
        Color(0xFF81C784),
        Color(0xFFE57373),
        Color(0xFFFFF176),
        Color(0xFF64B5F6),
      ],
      padNames: ['Sprout', 'Poppy', 'Butter', 'Sky'],
    ),
  ];

  static bool isProTheme(String id) =>
      all.any((t) => t.id == id && t.pro);

  static SimonThemeDef byId(String id, {required SimonThemeDef custom}) {
    if (id == 'custom') return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  // ---------------------------------------------------------------- pad styles
  /// 8 chunky pad styles. First 4 are FREE; 4–7 are PRO.
  /// Each entry is (shape, finish).
  static const List<String> padStyleNames = [
    'Chunky Square', // 0 square + plastic
    'Soft Circle', // 1 circle + plastic
    'Diamond Pop', // 2 diamond + plastic
    'Hex Bolt', // 3 hex + plastic
    'Metal Dome', // 4 circle + metal (PRO)
    'Wooden Disc', // 5 circle + wood (PRO)
    'Gem Cut', // 6 diamond + gem (PRO)
    'Iron Hex', // 7 hex + metal (PRO)
  ];

  static bool isProPadStyle(int i) => i >= 4;
}

/// Chunky physical pad shape.
enum PadShape { square, circle, diamond, hex }

/// Chunky physical pad material finish.
enum PadFinish { plastic, metal, wood, gem }

/// Maps a pad-style index (0..7) to its shape + finish.
(PadShape, PadFinish) padStyleSpec(int i) {
  switch (i.clamp(0, 7)) {
    case 0:
      return (PadShape.square, PadFinish.plastic);
    case 1:
      return (PadShape.circle, PadFinish.plastic);
    case 2:
      return (PadShape.diamond, PadFinish.plastic);
    case 3:
      return (PadShape.hex, PadFinish.plastic);
    case 4:
      return (PadShape.circle, PadFinish.metal);
    case 5:
      return (PadShape.circle, PadFinish.wood);
    case 6:
      return (PadShape.diamond, PadFinish.gem);
    default:
      return (PadShape.hex, PadFinish.metal);
  }
}
