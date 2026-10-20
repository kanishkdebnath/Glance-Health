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
