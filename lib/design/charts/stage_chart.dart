import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme.dart';
import '../tokens.dart';
import 'chart_paint.dart';

/// One lane per stage (top to bottom in [lanes] order) with a rounded
/// block for each stretch of time in that stage.
class StageChart extends StatelessWidget {
  const StageChart({
    super.key,
    required this.lanes,
    required this.blocks,
    required this.startLabel,
    required this.endLabel,
    required this.semanticsLabel,
    this.height = 120,
  });

  /// (name, colour) per lane.
  final List<(String, Color)> lanes;

  /// (lane index, start, end).
  final List<(int, DateTime, DateTime)> blocks;
  final String startLabel;
  final String endLabel;
  final double height;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _StagePainter(this, context.palette, context.type.chart),
      ),
    ),
  );
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.w, this.p, this.label);
  final StageChart w;
  final GlancePalette p;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    if (w.blocks.isEmpty) return;
    const left = 44.0, bottom = 18.0, laneGap = 4.0;
    final start = w.blocks
        .map((b) => b.$2)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = w.blocks
        .map((b) => b.$3)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final span = end.difference(start).inSeconds.clamp(1, 1 << 31);
    final laneH =
        (size.height - bottom - laneGap * (w.lanes.length - 1)) /
        w.lanes.length;
    double x(DateTime t) =>
        left + (size.width - left) * t.difference(start).inSeconds / span;

    for (final (i, (name, _)) in w.lanes.indexed) {
      final y = i * (laneH + laneGap);
      canvas.drawRRect(
        RRect.fromLTRBR(
          left,
          y,
          size.width,
          y + laneH,
          const Radius.circular(Radii.bar),
        ),
        Paint()..color = p.band.withValues(alpha: 0.6),
      );
      paintText(
        canvas,
        name,
        label,
        Offset(0, y + laneH / 2),
        anchor: TextAnchor.centerLeft,
      );
    }
    for (final (lane, from, to) in w.blocks) {
      final y = lane * (laneH + laneGap);
      final x0 = x(from), x1 = math.max(x(to), x0 + 1.5);
      canvas.drawRRect(
        RRect.fromLTRBR(
          x0,
          y,
          x1,
          y + laneH,
          Radius.circular(math.min(Radii.bar, (x1 - x0) / 2)),
        ),
        Paint()..color = w.lanes[lane].$2,
      );
    }
    paintText(
      canvas,
      w.startLabel,
      label,
      Offset(left, size.height),
      anchor: TextAnchor.bottomLeft,
    );
    paintText(
      canvas,
      w.endLabel,
      label,
      Offset(size.width, size.height),
      anchor: TextAnchor.bottomRight,
    );
  }

  @override
  bool shouldRepaint(_StagePainter old) => old.w != w || old.p != p;
}
