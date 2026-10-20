import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../motion.dart';
import '../palette.dart';
import '../theme.dart';

/// Small trend line with a soft gradient fill and an emphasised endpoint.
/// [band] shades the user's usual range behind the line.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.colors,
    required this.semanticsLabel,
    this.band,
    this.height = 34,
  });

  final List<num> values;
  final MetricColors colors;
  final (num, num)? band;
  final double height;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: height,
        width: double.infinity,
        // Draws in left to right the first time it appears.
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: motion(context, const Duration(milliseconds: 1000)),
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) => CustomPaint(
            painter: _SparkPainter(values, colors, band, context.palette, t),
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values, this.colors, this.band, this.p, this.progress);
  final List<num> values;
  final MetricColors colors;
  final (num, num)? band;
  final GlancePalette p;

  /// 0–1: how much of the line is drawn.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const pad = 5.0;
    final b = band;
    final all = [
      ...values,
      if (b != null) ...[b.$1, b.$2],
    ];
    final lo = all.reduce(math.min);
    final hi = all.reduce(math.max);
    final range = hi - lo == 0 ? 1 : hi - lo;
    double x(int i) => pad + (size.width - pad * 2) * i / (values.length - 1);
    double y(num v) => pad + (size.height - pad * 2) * (1 - (v - lo) / range);

    if (b != null) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          y(b.$2),
          size.width,
          y(b.$1),
          const Radius.circular(3),
        ),
        Paint()..color = p.band,
      );
    }

    final line = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      line.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(line)
      ..lineTo(x(values.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.main.withValues(alpha: 0.32),
            colors.second.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = colors.main
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    // The endpoint pops in as the line arrives.
    final pop = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    if (pop > 0) {
      final end = Offset(x(values.length - 1), y(values.last));
      canvas.drawCircle(end, 5.5 * pop, Paint()..color = p.surface);
      canvas.drawCircle(end, 3.5 * pop, Paint()..color = colors.main);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values ||
      old.band != band ||
      old.colors != colors ||
      old.p != p ||
      old.progress != progress;
}
