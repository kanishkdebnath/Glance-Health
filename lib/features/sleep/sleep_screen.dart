import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/baseline.dart';
import '../../core/format.dart';
import '../../core/goals.dart';
import '../../core/health/health_data_source.dart';
import '../../core/sleep_stats.dart';
import '../../design/charts/chart_paint.dart';
import '../../design/charts/goal_bars.dart';
import '../../design/charts/span_bars.dart';
import '../../design/charts/stage_chart.dart';
import '../../design/motion.dart';
import '../../design/palette.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../ui/detail_page.dart';
import '../../ui/goal_sheets.dart';
import '../../ui/status_pill.dart';

class SleepData {
  const SleepData({
    required this.today,
    required this.supported,
    required this.nights,
  });
  final DateTime today;
  final bool supported;

  /// One session per wake day over the baseline window, oldest first.
  final List<SleepSession> nights;

  SleepSession? get lastNight =>
      nights.isNotEmpty && nights.last.day == today ? nights.last : null;
}

final sleepDataProvider = FutureProvider<SleepData>((ref) async {
  final src = ref.watch(healthSourceProvider);
  final today = dayOf(ref.watch(clockProvider)());
  final from = DateTime(
    today.year,
    today.month,
    today.day - baselineWindowDays,
  );
  return SleepData(
    today: today,
    supported: (await src.supportedMetrics()).contains(Metric.sleep),
    nights: await src.sleepSessions(from, today),
  );
});

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final data = ref.watch(sleepDataProvider);
    final goals = ref.watch(goalsProvider);
    return ColoredBox(
      color: p.background,
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(sleepDataProvider.future),
        child: switch (data) {
          AsyncValue(:final value?) => _SleepBody(value, goals),
          AsyncValue(hasError: true) => SafeArea(
            child: LoadError(onRetry: () => ref.invalidate(sleepDataProvider)),
          ),
          _ => const SafeArea(child: DetailSkeleton()),
        },
      ),
    );
  }
}

class _SleepBody extends StatelessWidget {
  const _SleepBody(this.d, this.goals);
  final SleepData d;
  final Goals goals;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final today = d.today;
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];
    final byDay = {for (final n in d.nights) n.day: n};
    final weekNights = [for (final day in week) ?byDay[day]];
    final last = d.lastNight;
    final history = [
      for (final n in d.nights)
        if (n.day.isBefore(today)) n.asleep.inMinutes,
    ];

    final cards = <Widget>[
      if (!d.supported)
        _Note(
          'Not available from your device',
          'Your band or the Google Health app isn\'t sharing sleep with '
              'Health Connect. If that changes, nights will appear here.',
        )
      else ...[
        if (last != null) _StagesCard(last),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Space.m,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Last 7 nights', style: t.label)),
                  if (last != null)
                    StatusPill(compareToUsual(last.asleep.inMinutes, history)),
                ],
              ),
              GoalBars(
                values: [
                  for (final day in week)
                    (byDay[day]?.asleep.inMinutes ?? 0) / 60,
                ],
                goals: List.filled(7, goals.sleep.inMinutes / 60),
                colors: p.sleep,
                labels: [for (final day in week) weekdayInitial(day)],
                today: 6,
                showGoalLine: true,
                height: 120,
                format: (h) =>
                    hoursMinutes(Duration(minutes: (h * 60).round())),
                semanticsLabel: 'Hours asleep over the last 7 nights',
              ),
            ],
          ),
        ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Space.m,
            children: [
              Expanded(
                child: _SmallCard(
                  label: 'Sleep debt',
                  value: hoursMinutesParts(sleepDebt(weekNights, goals.sleep)),
                  note: 'Short of target over 7 nights',
                ),
              ),
              Expanded(
                child: _SmallCard(
                  label: 'Consistency',
                  value: switch (bedtimeSpread(weekNights)) {
                    final s? => [('±${s.inMinutes}', 'm')],
                    null => null,
                  },
                  note: 'Bedtime spread this week',
                ),
              ),
            ],
          ),
        ),
        if (weekNights.isNotEmpty) _ScheduleCard(week, byDay, d.nights),
      ],
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _NightHeader(d: d, goals: goals, week: week, byDay: byDay),
        Transform.translate(
          offset: const Offset(0, -Space.l),
          child: Container(
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.card),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              Space.screen,
              Space.l,
              Space.screen,
              Space.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, c) in cards.indexed) ...[
                  if (i > 0) detailGap,
                  Entrance(index: i, child: c),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The dark gradient header. It stays dark in both themes.
class _NightHeader extends StatelessWidget {
  const _NightHeader({
    required this.d,
    required this.goals,
    required this.week,
    required this.byDay,
  });
  final SleepData d;
  final Goals goals;
  final List<DateTime> week;
  final Map<DateTime, SleepSession> byDay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final last = d.lastNight;
    final on = p.onNight, on2 = p.onNight2;
    final fellAsleep = last?.segments
        .where((s) => s.stage != SleepStage.awake)
        .firstOrNull
        ?.start;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.night,
          stops: const [0, 0.58, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.s,
            Space.screen,
            Space.xxl + Space.l,
          ),
          child: Column(
            spacing: Space.l,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAST NIGHT',
                          style: t.eyebrow.copyWith(color: on2),
                        ),
                        Text('Sleep', style: t.title.copyWith(color: on)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showSleepTargetSheet(context),
                    tooltip: 'Edit sleep target',
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: on.withValues(alpha: 0.12),
                      foregroundColor: on,
                      fixedSize: const Size(44, 44),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, day) in week.indexed)
                    _WeekDot(
                      letter: weekdayInitial(day),
                      met: (byDay[day]?.asleep ?? Duration.zero) >= goals.sleep,
                      today: i == 6,
                      palette: p,
                    ),
                ],
              ),
              if (last == null)
                Text(
                  d.supported
                      ? 'No sleep synced for last night yet'
                      : 'Sleep isn\'t available from your device',
                  style: t.headline.copyWith(color: on),
                  textAlign: TextAlign.center,
                )
              else ...[
                Column(
                  children: [
                    MetricText(
                      hoursMinutesParts(last.asleep),
                      style: t.hero.copyWith(color: on),
                      unitColor: on2,
                    ),
                    const SizedBox(height: Space.xs),
                    Text(
                      'asleep · ${(last.asleep.inMinutes / goals.sleep.inMinutes * 100).round()}% of your ${hoursMinutes(goals.sleep)} target',
                      style: t.small.copyWith(color: on2),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _NightKv(
                      clockTime(fellAsleep ?? last.start),
                      'Fell asleep',
                    ),
                    _NightKv(clockTime(last.end), 'Woke up'),
                    _NightKv(hoursMinutes(last.inBed), 'In bed'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.letter,
    required this.met,
    required this.today,
    required this.palette,
  });
  final String letter;
  final bool met;
  final bool today;
  final GlancePalette palette;

  @override
  Widget build(BuildContext context) {
    final on = palette.onNight;
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: today ? on.withValues(alpha: 0.08) : null,
        border: Border.all(
          width: 2.5,
          color: today
              ? on
              : met
              ? palette.sleep.second.withValues(alpha: 0.85)
              : on.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        letter,
        style: context.type.chip.copyWith(color: today ? on : palette.onNight2),
        semanticsLabel: met ? '$letter, target met' : letter,
      ),
    );
  }
}

class _NightKv extends StatelessWidget {
  const _NightKv(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: context.type.metricSmall.copyWith(color: p.onNight),
          ),
          Text(label, style: context.type.small.copyWith(color: p.onNight2)),
        ],
      ),
    );
  }
}

class _StagesCard extends StatelessWidget {
  const _StagesCard(this.night);
  final SleepSession night;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final lanes = [
      (SleepStage.awake, 'Awake', p.stageAwake),
      (SleepStage.rem, 'REM', p.stageRem),
      (SleepStage.light, 'Light', p.stageLight),
      (SleepStage.deep, 'Deep', p.stageDeep),
    ];
    final totals = stageTotals(night.segments);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.m,
        children: [
          Text('Sleep stages', style: t.label),
          if (night.segments.isEmpty)
            Text(
              "Your device didn't record stages for this night.",
              style: t.small,
            )
          else ...[
            StageChart(
              lanes: [for (final l in lanes) (l.$2, l.$3)],
              blocks: [
                for (final s in night.segments)
                  (lanes.indexWhere((l) => l.$1 == s.stage), s.start, s.end),
              ],
              startLabel: clockTime(night.start),
              endLabel: clockTime(night.end),
              semanticsLabel: [
                for (final l in lanes) '${l.$2} ${hoursMinutes(totals[l.$1]!)}',
              ].join(', '),
            ),
            Wrap(
              spacing: Space.m,
              runSpacing: Space.xs,
              children: [
                for (final l in lanes)
                  LegendItem(l.$3, l.$2, value: hoursMinutes(totals[l.$1]!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(this.week, this.byDay, this.all);
  final List<DateTime> week;
  final Map<DateTime, SleepSession> byDay;
  final List<SleepSession> all;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final usual = usualRange([for (final n in all) minutesAfterNoon(n.start)]);
    // Minutes after noon; a wake time that wraps past the next noon
    // (rare: very late nights) is pushed a day later.
    (int, int) span(SleepSession n) {
      final a = minutesAfterNoon(n.start), b = minutesAfterNoon(n.end);
      return (a, b < a ? b + 1440 : b);
    }

    final spans = [
      for (final day in week) byDay[day] == null ? null : span(byDay[day]!),
    ];
    final points = [for (final s in spans) ?s].expand((s) => [s.$1, s.$2]);
    final ticks = niceTicks(
      (points.reduce((a, b) => a < b ? a : b) / 60).floor() * 60,
      (points.reduce((a, b) => a > b ? a : b) / 60).ceil() * 60,
    ).map((v) => (v / 60).round() * 60).toSet().toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.m,
        children: [
          Text('Schedule', style: t.label),
          SpanBars(
            spans: spans,
            labels: [for (final day in week) weekdayInitial(day)],
            colors: p.sleep,
            band: usual == null ? null : (usual.low, usual.high),
            ticks: ticks,
            tickLabel: (m) {
              final h = (12 + m ~/ 60) % 24;
              return '${h % 12 == 0 ? 12 : h % 12}${h < 12 ? 'a' : 'p'}';
            },
            downward: true,
            today: 6,
            height: 170,
            semanticsLabel: 'Bedtime and wake time over the last 7 nights',
          ),
          if (usual != null)
            Text('Shaded: your usual bedtime window', style: t.small),
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  const _SmallCard({
    required this.label,
    required this.value,
    required this.note,
  });
  final String label;
  final List<(String, String)>? value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.s,
        children: [
          Text(label, style: t.label),
          if (value case final v?)
            MetricText(v)
          else
            Text('—', style: t.metric.copyWith(color: context.palette.ink3)),
          Text(note, style: t.small),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Space.s,
      children: [
        Text(title, style: context.type.label),
        Text(body, style: context.type.small),
      ],
    ),
  );
}
