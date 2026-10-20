import 'package:flutter/material.dart';

import '../core/baseline.dart';
import '../core/health/health_data_source.dart';
import '../design/charts/sparkline.dart';
import '../design/metric_family.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';
import 'status_pill.dart';

/// Card for one metric: label, value, status and a 7-day sparkline.
/// Handles the "not available" and "no data yet" states itself.
class MetricCard<T> extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.family,
    required this.label,
    required this.reading,
    required this.valueParts,
    required this.status,
    required this.week,
    required this.semanticsUnit,
    this.band,
    this.onTap,
  });

  final MetricFamily family;
  final String label;
  final Reading<T> reading;
  final List<(String, String)> Function(T value) valueParts;
  final BaselineStatus status;
  final List<num> week;
  final (num, num)? band;
  final String semanticsUnit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final colors = p.family(family);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.s,
        children: [
          Row(
            children: [
              Icon(family.icon, size: 16, color: colors.main),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: t.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, size: 18, color: p.ink3),
            ],
          ),
          switch (reading) {
            Value<T>(:final value) => MetricText(
              valueParts(value),
              semanticsLabel:
                  '$label ${valueParts(value).map((e) => '${e.$1} ${e.$2}').join(' ')} $semanticsUnit',
            ),
            _ => Text('—', style: t.metric.copyWith(color: p.ink3)),
          },
          switch (reading) {
            Value() => StatusPill(status),
            Unsupported() => const UnavailablePill(),
            NoData() => Text('No data yet', style: t.small),
          },
          if (reading is Value && week.length > 1)
            Sparkline(
              values: week,
              colors: colors,
              band: band,
              semanticsLabel: '$label, last ${week.length} days',
            ),
        ],
      ),
    );
  }
}
