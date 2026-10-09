import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/simon_themes.dart';

// ---------------------------------------------------------------------------
// Cabinet: warm arcade-cabinet backdrop with a subtle vignette.
// ---------------------------------------------------------------------------
class Cabinet extends StatelessWidget {
  final SimonThemeDef theme;
  final Widget child;
  const Cabinet({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.cabinet, theme.cabinetDeep],
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Chunky physical button with weight: a top face over a darker base so it
// looks pressable, and it sinks when tapped.
// ---------------------------------------------------------------------------
class ArcadeButton extends StatefulWidget {
  final String label;
  final String? emoji;
  final VoidCallback onTap;
  final bool primary;
  final double width;
  final SimonThemeDef theme;
  final bool enabled;

  const ArcadeButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.emoji,
    this.primary = false,
    this.width = 240,
    this.enabled = true,
  });

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final face = widget.primary ? t.accent : t.cabinetLight;
    final edge = widget.primary ? t.accentDark : t.cabinetDeep;
    final fg = widget.primary ? t.cabinetDeep : t.text;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: EdgeInsets.only(bottom: _pressed ? 2 : 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: edge,
          boxShadow: _pressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(0, 5),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: widget.enabled
                ? face
                : t.cabinetLight.withValues(alpha: 0.5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.emoji == null
                ? widget.label
                : '${widget.emoji}  ${widget.label}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.enabled ? fg : t.muted,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class SectionTitle extends StatelessWidget {
  final String text;
  final SimonThemeDef theme;
  const SectionTitle(this.text, {super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: theme.accent,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 2.2,
        ),
      ),
    );
  }
}

/// Small "PRO" tag shown on locked premium content.
class ProTag extends StatelessWidget {
  final SimonThemeDef theme;
  const ProTag({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.accent,
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: theme.cabinetDeep,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chunky physical pad: a beveled push-button rendered with realistic depth.
// [light] 0..1 animates the lit state; [wrong] flashes a red "oops" tint.
// ---------------------------------------------------------------------------
class ChunkyPad extends StatefulWidget {
  final Color color;
  final bool lit;
  final bool wrong;
  final PadShape shape;
  final PadFinish finish;
  final VoidCallback onTap;

  const ChunkyPad({
    super.key,
    required this.color,
    required this.lit,
    required this.wrong,
    required this.shape,
    required this.finish,
    required this.onTap,
  });

  @override
  State<ChunkyPad> createState() => _ChunkyPadState();
}

class _ChunkyPadState extends State<ChunkyPad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;
  double _press = 0; // 0..1 while finger is down

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _ctl.addListener(() => setState(() {}));
    if (widget.lit) _ctl.value = 1;
  }

  @override
  void didUpdateWidget(ChunkyPad old) {
    super.didUpdateWidget(old);
    if (widget.lit != old.lit) {
      if (widget.lit) {
        _ctl.forward(from: 0);
      } else {
        _ctl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _press = 1),
      onTapUp: (_) => setState(() => _press = 0),
      onTapCancel: () => setState(() => _press = 0),
      onTap: widget.onTap,
      child: Transform.scale(
        scale: 1 - _press * 0.06,
        child: CustomPaint(
          painter: _PadPainter(
            color: widget.color,
            light: _ctl.value,
            wrong: widget.wrong,
            shape: widget.shape,
            finish: widget.finish,
          ),
        ),
      ),
    );
  }
}

class _PadPainter extends CustomPainter {
  final Color color;
  final double light;
  final bool wrong;
  final PadShape shape;
  final PadFinish finish;

  _PadPainter({
    required this.color,
    required this.light,
    required this.wrong,
    required this.shape,
    required this.finish,
  });

  Path _path(Size s, double inset) {
    final r = s.width / 2 - inset;
    final c = Offset(s.width / 2, s.height / 2);
    switch (shape) {
      case PadShape.circle:
        return Path()..addOval(Rect.fromCircle(center: c, radius: r));
      case PadShape.diamond:
        return Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close();
      case PadShape.hex:
        final p = Path();
        for (int k = 0; k < 6; k++) {
          final a = pi / 3 * k - pi / 6;
          final pt = Offset(c.dx + r * cos(a), c.dy + r * sin(a));
          if (k == 0) {
            p.moveTo(pt.dx, pt.dy);
          } else {
            p.lineTo(pt.dx, pt.dy);
          }
        }
        p.close();
        return p;
      case PadShape.square:
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCircle(center: c, radius: r), Radius.circular(r * 0.32)));
    }
  }

  Color _dark(Color c, double f) => Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green * f).round(),
        (c.blue * f).round(),
      );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final glowC = Color.lerp(color, Colors.white, 0.25)!;
    final dim = _dark(color, 0.42);
    final face = Color.lerp(dim, color, light)!;
    final litFace = Color.lerp(face, Colors.white, light * 0.35)!;

    // Warm light halo behind a lit pad (a physical lamp, not UI neon).
    if (light > 0) {
      final halo = Paint()
        ..shader = RadialGradient(
          colors: [
            glowC.withValues(alpha: 0.5 * light),
            glowC.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(s / 2, s / 2), radius: s * 0.62));
      canvas.drawCircle(Offset(s / 2, s / 2), s * 0.62, halo);
    }

    // Drop shadow: the pad floats above the cabinet.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.045);
    canvas.save();
    canvas.translate(0, s * 0.05);
    canvas.drawPath(_path(size, s * 0.06), shadow);
    canvas.restore();

    // Bezel: dark beveled rim around the face.
    canvas.drawPath(_path(size, s * 0.05), Paint()..color = _dark(color, 0.5));

    // Face.
    var faceColor = litFace;
    if (wrong) faceColor = Color.lerp(faceColor, const Color(0xFFFF2222), 0.7)!;
    canvas.drawPath(_path(size, s * 0.10), Paint()..color = faceColor);

    // Material finish details.
    final c = Offset(s / 2, s / 2);
    final r = s / 2 - s * 0.10;
    if (finish == PadFinish.metal) {
      // Brushed metal: a light band across the top.
      final band = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawPath(_path(size, s * 0.10), band);
    } else if (finish == PadFinish.wood) {
      // Wooden ring around the face.
      canvas.drawPath(
        _path(size, s * 0.10),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..color = const Color(0xFF6B4423).withValues(alpha: 0.85),
      );
    } else if (finish == PadFinish.gem) {
      // Facet lines from the center.
      final facet = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = Colors.white.withValues(alpha: 0.4);
      final pts = shape == PadShape.diamond
          ? [Offset(c.dx, c.dy - r), Offset(c.dx + r, c.dy), Offset(c.dx, c.dy + r), Offset(c.dx - r, c.dy)]
          : [Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r)];
      for (final p in pts) {
        canvas.drawLine(c, p, facet);
      }
    }

    // Top-left specular highlight: the plastic sheen. Shrinks when lit
    // because the whole face is already bright.
    final sheen = Paint()
      ..color = Colors.white.withValues(alpha: 0.30 * (1 - light * 0.5))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(s * 0.38, s * 0.32), width: s * 0.30, height: s * 0.18),
      sheen,
    );

    // Lit rim: a crisp white edge when the lamp is on.
    if (light > 0.05) {
      canvas.drawPath(
        _path(size, s * 0.10),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.025
          ..color = Colors.white.withValues(alpha: 0.85 * light),
      );
    }

    // Inner bevel: dark groove where the face meets the bezel.
    canvas.drawPath(
      _path(size, s * 0.10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..color = Colors.black.withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(_PadPainter old) =>
      old.color != color ||
      old.light != light ||
      old.wrong != wrong ||
      old.shape != shape ||
      old.finish != finish;
}
