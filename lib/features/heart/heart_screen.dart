import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/baseline.dart';
import '../../core/format.dart';
import '../../core/health/health_data_source.dart';
import '../../design/charts/chart_paint.dart';
import '../../design/charts/span_bars.dart';
import '../../design/charts/sparkline.dart';
import '../../design/metric_family.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../ui/detail_page.dart';
import '../../ui/status_explainer.dart';
import '../../ui/status_pill.dart';

class HeartData {
  const HeartData({
    required this.today,
    required this.supported,
    required this.resting,
    required this.range,
    required this.hrv,
    required this.spo2,
  });
  final DateTime today;
  final Set<Metric> supported;

  /// About a year of daily resting heart rate.
  final DailySeries<int> resting;

  /// The last 7 days.
  final DailySeries<HeartRange> range;
  final DailySeries<double> hrv;
  final DailySeries<double> spo2;
}

final heartDataProvider = FutureProvider<HeartData>((ref) async {
  final src = ref.watch(healthSourceProvider);
  final today = dayOf(ref.watch(clockProvider)());
  DateTime ago(int n) => DateTime(today.year, today.month, today.day - n);
  final supported = await src.supportedMetrics();
  return HeartData(
    today: today,
    supported: supported,
    resting: await src.restingHeartRate(ago(364), today),
    range: supported.contains(Metric.heartRateRange)
        ? await src.heartRateRange(ago(6), today)
        : const {},
    hrv: await src.hrv(ago(baselineWindowDays), today),
    spo2: await src.spo2(ago(baselineWindowDays), today),
  );
});

enum HeartPeriod {
  week('7D', 7),
  month('30D', 30),
  quarter('90D', 90),
  year('Year', 365);

  const HeartPeriod(this.label, this.days);
  final String label;
  final int days;
}

class HeartScreen extends ConsumerStatefulWidget {
  const HeartScreen({super.key});

  @override
  ConsumerState<HeartScreen> createState() => _HeartScreenState();
}

class _HeartScreenState extends ConsumerState<HeartScreen> {
  var _range = HeartPeriod.month;

  @override
  Widget build(BuildContext context) => DetailPage<HeartData>(
    family: MetricFamily.heart,
    provider: heartDataProvider,
    header: DetailHeader(
      title: 'Heart',
      icon: Icons.info_outline_rounded,
      tooltip: 'How "usual" works',
      onPressed: () => showStatusExplainer(context),
    ),
    builder: (context, d) => [
      Segmented(
        values: HeartPeriod.values,
        selected: _range,
        labelOf: (r) => r.label,
        onChanged: (r) => setState(() => _range = r),
      ),
      const SizedBox(height: Space.l),
      ..._resting(context, d),
      detailGap,
      if (d.supported.contains(Metric.heartRateRange)) ...[
        _DayRangeCard(d),
        detailGap,
      ],
      RowList(
        rows: [
          _SecondaryRow(
            icon: Icons.monitor_heart_rounded,
            label: 'HRV',
            series: d.hrv,
            supported: d.supported.contains(Metric.hrv),
            today: d.today,
            format: (v) => '${v.round()} ms',
          ),
          _SecondaryRow(
            icon: Icons.water_drop_rounded,
            label: 'SpO2',
            series: d.spo2,
            supported: d.supported.contains(Metric.spo2),
            today: d.today,
            format: (v) => '${v.round()}%',
          ),
        ],
      ),
    ],
  );

  List<Widget> _resting(BuildContext context, HeartData d) {
    final p = context.palette;
    final t = context.type;
    if (!d.supported.contains(Metric.restingHeartRate)) {
      return [
        Text('Resting heart rate', style: t.label),
        const SizedBox(height: Space.s),
        const Align(alignment: Alignment.centerLeft, child: UnavailablePill()),
      ];
    }
    final days = d.resting.keys.toList()..sort();
    final latest = days.isEmpty ? null : days.last;
    final history = [
      for (final e in d.resting.entries)
        if (e.key.isBefore(d.today) &&
            !e.key.isBefore(
              DateTime(
                d.today.year,
                d.today.month,
                d.today.day - baselineWindowDays,
              ),
            ))
          e.value,
    ];
    final usual = usualRange(history);
    final from = DateTime(
      d.today.year,
      d.today.month,
      d.today.day - _range.days + 1,
    );
    final shown = [
      for (final day in days)
        if (!day.isBefore(from)) d.resting[day]!,
    ];
    final value = latest == null ? null : d.resting[latest]!;
    final all = [
      ...shown,
      if (usual != null) ...[usual.low, usual.high],
    ];
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latest == d.today || latest == null
                      ? 'RESTING'
                      : 'RESTING · ${shortDate(latest)}',
                  style: t.eyebrow,
                ),
                if (value == null)
                  Text('—', style: t.hero.copyWith(color: p.ink3))
                else
                  MetricText([('$value', ' bpm')], style: t.hero),
              ],
            ),
          ),
          if (value != null) StatusPill(compareToUsual(value, history)),
        ],
      ),
      const SizedBox(height: Space.l),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.m,
          children: [
            if (shown.length > 1)
              Sparkline(
                values: shown,
                colors: p.heart,
                band: usual == null ? null : (usual.low, usual.high),
                height: 140,
                ticks: niceTicks(
                  all.reduce(math.min).floor(),
                  all.reduce(math.max).ceil(),
                ),
                semanticsLabel: 'Resting heart rate, last ${_range.label}',
              )
            else
              Text('Not enough days to draw a trend yet.', style: t.small),
            Text(
              usual == null
                  ? 'Learning your usual: ${history.length} of $baselineMinDays days.'
                  : 'Your usual: ${usual.low.round()}–${usual.high.round()} bpm, from the last 30 days.',
              style: t.small,
            ),
          ],
        ),
      ),
    ];
  }
}

class _DayRangeCard extends StatelessWidget {
  const _DayRangeCard(this.d);
  final HeartData d;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(d.today.year, d.today.month, d.today.day - i),
    ];
    final spans = [for (final day in week) d.range[day]];
    final values = [
      for (final s in spans)
        if (s != null) ...[s.min, s.max],
    ];
    final todayRange = d.range[d.today];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.m,
        children: [
          Row(
            children: [
              Expanded(child: Text('Day range', style: t.label)),
              if (todayRange != null)
                Text(
                  '${todayRange.min}–${todayRange.max} bpm today',
                  style: t.small.copyWith(color: p.ink),
                ),
            ],
          ),
          if (values.isEmpty)
            Text('No heart rate in the last 7 days.', style: t.small)
          else
            SpanBars(
              spans: [for (final s in spans) s == null ? null : (s.min, s.max)],
              dots: [for (final day in week) d.resting[day]],
              labels: [for (final day in week) weekdayInitial(day)],
              colors: p.heart,
              ticks: niceTicks(
                values.reduce(math.min),
                values.reduce(math.max),
              ),
              tickLabel: (v) => '${v.round()}',
              today: 6,
              height: 140,
              semanticsLabel:
                  'Lowest and highest heart rate each day, last 7 days',
            ),
          Text('Dots mark resting heart rate.', style: t.small),
        ],
      ),
    );
  }
}

class _SecondaryRow extends StatelessWidget {
  const _SecondaryRow({
    required this.icon,
    required this.label,
    required this.series,
    required this.supported,
    required this.today,
    required this.format,
  });
  final IconData icon;
  final String label;
  final DailySeries<double> series;
  final bool supported;
  final DateTime today;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final value = series[today];
    final history = [
      for (final e in series.entries)
        if (e.key.isBefore(today)) e.value,
    ];
    return InfoRow(
      icon: icon,
      iconColor: p.heart.main,
      label: label,
      detail: !supported
          ? 'Not available from your device'
          : value == null
          ? 'No data yet today'
          : switch (compareToUsual(value, history)) {
              BaselineStatus.below => 'Below usual',
              BaselineStatus.typical => 'Typical',
              BaselineStatus.above => 'Above usual',
              BaselineStatus.learning => 'Learning your usual',
            },
      value: value == null ? '—' : format(value),
    );
  }
}
