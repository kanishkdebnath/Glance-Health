import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Shared drawing helpers for the chart painters.

enum TextAnchor { bottomCenter, bottomLeft, bottomRight, centerLeft, center }

void paintText(
  Canvas canvas,
  String text,
  TextStyle style,
  Offset at, {
  TextAnchor anchor = TextAnchor.center,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final o = switch (anchor) {
    TextAnchor.bottomCenter => at - Offset(tp.width / 2, tp.height),
    TextAnchor.bottomLeft => at - Offset(0, tp.height),
    TextAnchor.bottomRight => at - Offset(tp.width, tp.height),
    TextAnchor.centerLeft => at - Offset(0, tp.height / 2),
    TextAnchor.center => at - Offset(tp.width / 2, tp.height / 2),
  };
  tp.paint(canvas, o);
}

void dashLine(
  Canvas canvas,
  Offset a,
  Offset b,
  Paint paint, {
  double dash = 3,
  double gap = 3,
}) {
  final d = b - a;
  final len = d.distance;
  if (len == 0) return;
  final dir = d / len;
  for (double s = 0; s < len; s += dash + gap) {
    final e = (s + dash).clamp(0, len).toDouble();
    canvas.drawLine(a + dir * s, a + dir * e, paint);
  }
}

/// Up to [count] round values inside [lo]–[hi], for axis labels. Ticks
/// stay within the data so the axis never stretches to reach them.
List<num> niceTicks(num lo, num hi, {int count = 4}) {
  if (hi <= lo) return [lo];
  final raw = (hi - lo) / (count - 1);
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor());
  final step = [
    1,
    2,
    2.5,
    5,
    10,
  ].map((m) => m * mag).firstWhere((s) => s >= raw);
  final first = (lo / step).ceil() * step;
  return [for (var v = first; v <= hi + step * 0.01; v += step) v];
}
