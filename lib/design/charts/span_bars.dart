import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme.dart';
import 'chart_paint.dart';

/// One vertical span per day between two values, with an optional dot:
/// sleep schedule (bedtime to wake, time running downward) and the day's
/// heart-rate range (low to high, resting value as the dot).
class SpanBars extends StatelessWidget {
  const SpanBars({
    super.key,
    required this.spans,
    required this.labels,
    required this.colors,
    required this.tickLabel,
    required this.semanticsLabel,
    this.dots,
    this.band,
    this.ticks = const [],
    this.downward = false,
    this.height = 140,
    this.today,
  });

  /// (low, high) per bar; null for a day without data.
  final List<(num, num)?> spans;
  final List<num?>? dots;
  final List<String> labels;
  final MetricColors colors;

  /// Shaded usual range behind the bars.
  final (num, num)? band;
  final List<num> ticks;
  final String Function(num) tickLabel;

  /// True when larger values sit lower, e.g. later clock times.
  final bool downward;
  final double height;
  final int? today;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SpanPainter(this, context.palette, context.type.chart),
      ),
    ),
  );
}

class _SpanPainter extends CustomPainter {
  _SpanPainter(this.w, this.p, this.label);
  final SpanBars w;
  final GlancePalette p;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    final n = w.spans.length;
    final values = [
      for (final s in w.spans)
        if (s != null) ...[s.$1, s.$2],
      ...?w.dots?.whereType<num>(),
      ...w.ticks,
    ];
    if (n == 0 || values.isEmpty) return;
    const right = 40.0, top = 6.0, bottom = 20.0;
    var lo = values.reduce(math.min), hi = values.reduce(math.max);
    if (hi == lo) hi = lo + 1;
    final plotW = size.width - right;
    double y(num v) {
      final f = (v - lo) / (hi - lo);
      return top + (size.height - top - bottom) * (w.downward ? f : 1 - f);
    }

    final b = w.band;
    if (b != null) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          0,
          math.min(y(b.$1), y(b.$2)),
          plotW,
          math.max(y(b.$1), y(b.$2)),
          const Radius.circular(3),
        ),
        Paint()..color = p.band,
      );
    }
    final grid = Paint()..color = p.line;
    for (final t in w.ticks) {
      canvas.drawLine(Offset(0, y(t)), Offset(plotW, y(t)), grid);
      paintText(
        canvas,
        w.tickLabel(t),
        label,
        Offset(plotW + 6, y(t)),
        anchor: TextAnchor.centerLeft,
      );
    }

    final slot = plotW / n;
    final bw = math.min(12.0, slot * 0.5);
    for (var i = 0; i < n; i++) {
      final cx = slot * (i + 0.5);
      final s = w.spans[i];
      if (s != null) {
        final rect = Rect.fromLTRB(
          cx - bw / 2,
          math.min(y(s.$1), y(s.$2)),
          cx + bw / 2,
          math.max(y(s.$1), y(s.$2)),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(bw / 2)),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [w.colors.second, w.colors.main],
            ).createShader(rect),
        );
      }
      final d = w.dots?[i];
      if (d != null) {
        canvas.drawCircle(
          Offset(cx, y(d)),
          bw / 2 + 2,
          Paint()..color = p.surface,
        );
        canvas.drawCircle(Offset(cx, y(d)), bw / 2 - 1, Paint()..color = p.ink);
      }
      if (i < w.labels.length) {
        paintText(
          canvas,
          w.labels[i],
          w.today == i
              ? label.copyWith(color: p.ink, fontWeight: FontWeight.w700)
              : label,
          Offset(cx, size.height),
          anchor: TextAnchor.bottomCenter,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SpanPainter old) => old.w != w || old.p != p;
}
