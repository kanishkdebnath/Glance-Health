import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../palette.dart';
import '../theme.dart';
import 'chart_paint.dart';

/// One cell per day, weeks in columns with Monday on top. [levels] maps a
/// day (local midnight) to 0–1; days without a level are outlined, never
/// shown as zero.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.levels,
    required this.end,
    required this.colors,
    required this.semanticsLabel,
    this.weeks = 53,
  });

  final Map<DateTime, double> levels;
  final DateTime end;
  final MetricColors colors;
  final int weeks;
  final String semanticsLabel;

  /// Opacity steps for the five legend swatches after "no data".
  static const steps = [0.3, 0.55, 0.8, 1.0];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 2.0, top = 16.0;
          final cell = (c.maxWidth - gap * (weeks - 1)) / weeks;
          return SizedBox(
            height: top + cell * 7 + gap * 6,
            width: c.maxWidth,
            child: CustomPaint(
              painter: _HeatPainter(
                this,
                context.palette,
                context.type.chart,
                cell,
                gap,
                top,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter(this.w, this.p, this.label, this.cell, this.gap, this.top);
  final Heatmap w;
  final GlancePalette p;
  final TextStyle label;
  final double cell, gap, top;

  static const _months = 'JFMAMJJASOND';

  @override
  void paint(Canvas canvas, Size size) {
    final endDay = DateTime(w.end.year, w.end.month, w.end.day);
    final lastMonday = endDay.subtract(Duration(days: endDay.weekday - 1));
    final first = DateTime(
      lastMonday.year,
      lastMonday.month,
      lastMonday.day - 7 * (w.weeks - 1),
    );
    final r = Radius.circular(math.min(2, cell / 3));
    final outline = Paint()
      ..color = p.line
      ..style = PaintingStyle.stroke;
    int? lastMonth;
    for (var col = 0; col < w.weeks; col++) {
      final monday = DateTime(first.year, first.month, first.day + col * 7);
      // Label each month at its first column, skipping a partial first month.
      if (monday.month != lastMonth) {
        if ((col > 0 || monday.day <= 7) && col < w.weeks - 2) {
          paintText(
            canvas,
            _months[monday.month - 1],
            label,
            Offset(col * (cell + gap), top - 3),
            anchor: TextAnchor.bottomLeft,
          );
        }
        lastMonth = monday.month;
      }
      for (var row = 0; row < 7; row++) {
        final day = DateTime(monday.year, monday.month, monday.day + row);
        if (day.isAfter(endDay)) continue;
        final rect = Rect.fromLTWH(
          col * (cell + gap),
          top + row * (cell + gap),
          cell,
          cell,
        );
        final v = w.levels[day];
        if (v == null) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect.deflate(0.5), r),
            outline,
          );
          continue;
        }
        final step =
            Heatmap.steps[(v * Heatmap.steps.length).floor().clamp(
              0,
              Heatmap.steps.length - 1,
            )];
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, r),
          Paint()..color = w.colors.main.withValues(alpha: step),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.w != w || old.p != p || old.cell != cell;
}
