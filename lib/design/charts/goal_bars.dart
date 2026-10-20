import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme.dart';
import '../tokens.dart';
import '../typography.dart';
import 'chart_paint.dart';

/// Daily bars against a goal. Met days use the family gradient, unmet days
/// the dim colour, and today is half-tone until it's over. The goal line
/// steps when goals differ by day (e.g. weekend goals).
class GoalBars extends StatelessWidget {
  const GoalBars({
    super.key,
    required this.values,
    required this.colors,
    required this.format,
    required this.semanticsLabel,
    this.goals,
    this.labels = const [],
    this.today,
    this.showGoalLine = false,
    this.valueLabels = const {},
    this.height = 140,
    this.gap,
  });

  final List<num> values;

  /// One goal per bar, or null for bars without a goal.
  final List<num>? goals;
  final List<String> labels;
  final int? today;
  final MetricColors colors;
  final bool showGoalLine;
  final Set<int> valueLabels;
  final double height;
  final double? gap;
  final String Function(num) format;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _BarsPainter(this, context.palette, context.type),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.w, this.p, this.t);
  final GoalBars w;
  final GlancePalette p;
  final GlanceType t;

  @override
  void paint(Canvas canvas, Size size) {
    final n = w.values.length;
    if (n == 0) return;
    final hasLabels = w.labels.isNotEmpty;
    final pb = hasLabels ? 20.0 : 4.0;
    const pt = 18.0;
    final gap = w.gap ?? math.max(3.0, size.width / n * 0.32);
    final bw = (size.width - gap * (n - 1)) / n;
    final goals = w.goals;
    final top = [...w.values, ...?goals].fold<num>(0, math.max) * 1.12;
    final max = top <= 0 ? 1 : top;
    final base = size.height - pb;
    double y(num v) => pt + (base - pt) * (1 - v / max);

    // The whole chart draws into one layer so the goal pill can clear the
    // marks behind it and redraw them blurred.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()..color = p.line,
    );

    void bars(Canvas canvas, {bool labels = true}) {
      for (var i = 0; i < n; i++) {
        final v = w.values[i];
        final x = i * (bw + gap);
        final g = goals?[i];
        final met = g == null || v >= g;
        final isToday = w.today == i;
        if (v > 0) {
          final rect = Rect.fromLTRB(x, y(v), x + bw, base);
          final radius = Radius.circular(math.min(Radii.bar, bw / 2));
          final paint = Paint();
          if (met) {
            final a = isToday ? 0.6 : 1.0;
            paint.shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                w.colors.second.withValues(alpha: a),
                w.colors.main.withValues(alpha: a),
              ],
            ).createShader(rect);
          } else {
            paint.color = w.colors.dim;
          }
          canvas.drawRRect(
            RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
            paint,
          );
        }
        if (labels && w.valueLabels.contains(i)) {
          paintText(
            canvas,
            w.format(v),
            t.chart.copyWith(color: p.ink, fontWeight: FontWeight.w600),
            Offset(x + bw / 2, y(v) - 4),
            anchor: TextAnchor.bottomCenter,
          );
        }
        if (labels &&
            hasLabels &&
            i < w.labels.length &&
            w.labels[i].isNotEmpty) {
          final style = isToday
              ? t.chart.copyWith(color: p.ink, fontWeight: FontWeight.w700)
              : t.chart;
          paintText(
            canvas,
            w.labels[i],
            style,
            Offset(x + bw / 2, size.height),
            anchor: TextAnchor.bottomCenter,
          );
        }
      }
    }

    final showGoal = w.showGoalLine && goals != null && goals.isNotEmpty;
    void goalLine(Canvas canvas) {
      if (!showGoal) return;
      final line = Paint()
        ..color = p.ink2
        ..strokeWidth = 1.2;
      var prev = Offset(0, y(goals[0]));
      for (var i = 0; i < n; i++) {
        final x0 = i == 0 ? 0.0 : i * (bw + gap) - gap / 2;
        final x1 = i == n - 1 ? size.width : i * (bw + gap) + bw + gap / 2;
        final start = Offset(x0, y(goals[i]));
        if (start.dy != prev.dy) dashLine(canvas, prev, start, line);
        final end = Offset(x1, y(goals[i]));
        dashLine(canvas, start, end, line);
        prev = end;
      }
    }

    bars(canvas);
    goalLine(canvas);

    if (showGoal) {
      // Frosted-glass pill on the line: what's behind it shows through,
      // blurred, under a light tint.
      final tp = TextPainter(
        text: TextSpan(
          text: 'Goal ${w.format(goals[0])}',
          style: t.chart.copyWith(color: p.ink, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pill = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          y(goals[0]) - tp.height / 2 - 3,
          tp.width + 14,
          tp.height + 6,
        ),
        const Radius.circular(Radii.chip),
      );
      canvas.drawRRect(pill, Paint()..blendMode = BlendMode.clear);
      canvas
        ..save()
        ..clipRRect(pill)
        ..saveLayer(
          pill.outerRect,
          Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        );
      bars(canvas, labels: false);
      goalLine(canvas);
      canvas
        ..restore()
        ..restore();
      canvas.drawRRect(
        pill,
        Paint()..color = p.surface.withValues(alpha: 0.35),
      );
      canvas.drawRRect(
        pill,
        Paint()
          ..color = p.ink.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke,
      );
      tp.paint(canvas, Offset(7, pill.top + 3));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.w != w || old.p != p;
}
