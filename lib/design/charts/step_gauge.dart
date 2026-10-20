import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';
import '../theme.dart';

/// 270° progress arc. The triangle outside the arc marks [pace]: where the
/// user usually is by this time of day (0–1 of the goal).
class StepGauge extends StatelessWidget {
  const StepGauge({
    super.key,
    required this.value,
    required this.goal,
    required this.colors,
    required this.semanticsLabel,
    this.pace,
    this.size = 240,
    this.strokeWidth,
    this.showTicks = true,
    this.child,
  });

  final num value;
  final num goal;
  final MetricColors colors;
  final double? pace;
  final double size;
  final double? strokeWidth;
  final bool showTicks;
  final Widget? child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox.square(
        dimension: size,
        // Sweeps from 0 on first show, then from the old value to the new.
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0,
            end: goal <= 0 ? 0 : (value / goal).clamp(0, 1).toDouble(),
          ),
          duration: motion(context, const Duration(milliseconds: 1100)),
          curve: Curves.easeOutCubic,
          builder: (context, f, inner) => CustomPaint(
            painter: _GaugePainter(
              fraction: f,
              pace: pace,
              colors: colors,
              palette: context.palette,
              strokeWidth: strokeWidth ?? size * 0.075,
              showTicks: showTicks && size > 150,
            ),
            child: inner,
          ),
          child: Center(child: ExcludeSemantics(child: child)),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.pace,
    required this.colors,
    required this.palette,
    required this.strokeWidth,
    required this.showTicks,
  });

  final double fraction;
  final double? pace;
  final MetricColors colors;
  final GlancePalette palette;
  final double strokeWidth;
  final bool showTicks;

  static const _start = 135 * math.pi / 180;
  static const _sweep = 270 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final sw = strokeWidth;
    final r = size.width / 2 - sw / 2 - (pace != null ? 14 : 1);
    final rect = Rect.fromCircle(center: c, radius: r);
    Offset at(double a, double radius) =>
        c + Offset(math.cos(a), math.sin(a)) * radius;

    canvas.drawArc(
      rect,
      _start,
      _sweep,
      false,
      Paint()
        ..color = colors.track
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );

    if (showTicks) {
      final tick = Paint()
        ..color = palette.ink3.withValues(alpha: 0.6)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i <= 40; i++) {
        final a = _start + _sweep * i / 40;
        final r1 = r - sw / 2 - 6;
        final r2 = r1 - (i % 10 == 0 ? 8 : 4);
        canvas.drawLine(
          at(a, r1),
          at(a, r2),
          tick..strokeWidth = i % 10 == 0 ? 1.6 : 1,
        );
      }
    }

    if (fraction > 0) {
      // Rotated slightly back so the round start cap stays the main colour.
      const lead = 10 * math.pi / 180;
      canvas.drawArc(
        rect,
        _start,
        math.max(_sweep * fraction, 0.01),
        false,
        Paint()
          ..shader = SweepGradient(
            endAngle: _sweep + 2 * lead,
            colors: [colors.main, colors.second],
            transform: const GradientRotation(_start - lead),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }

    final pc = pace;
    if (pc != null) {
      final a = _start + _sweep * pc.clamp(0, 1);
      final r0 = r + sw / 2 + 3;
      final r1 = r0 + 10;
      final half = 6 / r1; // base about 12px wide, pointing at the arc
      final tri = Path()
        ..moveTo(at(a, r0).dx, at(a, r0).dy)
        ..lineTo(at(a - half, r1).dx, at(a - half, r1).dy)
        ..lineTo(at(a + half, r1).dx, at(a + half, r1).dy)
        ..close();
      canvas.drawPath(tri, Paint()..color = palette.ink);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction ||
      old.pace != pace ||
      old.colors != colors ||
      old.palette != palette;
}
