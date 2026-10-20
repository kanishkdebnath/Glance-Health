import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/goals.dart';
import '../../core/health/health_data_source.dart';
import '../../core/steps_stats.dart';
import '../../design/charts/goal_bars.dart';
import '../../design/charts/heatmap.dart';
import '../../design/metric_family.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../ui/detail_page.dart';
import '../../ui/goal_sheets.dart';
import 'steps_data.dart';

enum StepsRange {
  today('Today', 1),
  week('7D', 7),
  month('30D', 30),
  quarter('90D', 91),
  year('Year', yearDays);

  const StepsRange(this.label, this.days);
  final String label;
  final int days;
}

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});

  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  var _range = StepsRange.today;

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    return DetailPage<StepsData>(
      family: MetricFamily.steps,
      provider: stepsDataProvider,
      header: DetailHeader(
        title: 'Steps',
        icon: Icons.edit_rounded,
        tooltip: 'Edit step goal',
        onPressed: () => showStepGoalSheet(context),
      ),
      builder: (context, d) => [
        Segmented(
          values: StepsRange.values,
          selected: _range,
          labelOf: (r) => r.label,
          onChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: Space.l),
        ...switch (_range) {
          StepsRange.today => _today(context, d, goals),
          StepsRange.week || StepsRange.month => _days(context, d, goals),
          StepsRange.quarter => _weeks(context, d, goals),
          StepsRange.year => _year(context, d, goals),
        },
      ],
    );
  }

  List<Widget> _today(BuildContext context, StepsData d, Goals goals) {
    final p = context.palette;
    final t = context.type;
    final steps = d.daily[d.today] ?? 0;
    final goal = goals.stepsFor(d.today);
    final s = streaks(d.daily, goals.stepsFor, d.today);
    final active = d.activeToday;
    return [
      AnimatedCount(steps, style: t.hero),
      const SizedBox(height: Space.xs),
      Text(
        [
          '${(steps / goal * 100).round()}% of ${thousands(goal)}',
          if (d.usualByNow case final u?)
            'usually ${thousands(u)} by ${clockTime(d.now)}',
        ].join(' · '),
        style: t.small,
      ),
      const SizedBox(height: Space.l),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.s,
          children: [
            Text('By hour', style: t.label),
            GoalBars(
              values: d.todayHours,
              colors: p.steps,
              today: d.now.hour,
              gap: 2,
              height: 130,
              labels: [for (var h = 0; h < 24; h++) h % 6 == 0 ? '$h' : ''],
              format: thousands,
              semanticsLabel: 'Steps by hour today',
            ),
          ],
        ),
      ),
      detailGap,
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.m,
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.local_fire_department_rounded,
                label: 'Streak',
                value: [('${s.current}', s.current == 1 ? ' day' : ' days')],
                note: s.graceLeft > 0
                    ? '1 grace day left this week'
                    : 'Grace day used this week',
              ),
            ),
            Expanded(
              child: _StatCard(
                icon: Icons.bolt_rounded,
                label: 'Active',
                value: switch (active) {
                  Value(:final value) => [('$value', ' min')],
                  _ => null,
                },
                note: switch (active) {
                  Unsupported() => 'Not available from your device',
                  NoData() => 'No data yet',
                  Value() => '${d.activeWeek} min this week',
                },
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _days(BuildContext context, StepsData d, Goals goals) {
    final p = context.palette;
    final t = context.type;
    final n = _range.days;
    final days = [
      for (var i = n - 1; i >= 0; i--)
        DateTime(d.today.year, d.today.month, d.today.day - i),
    ];
    final values = [for (final day in days) d.daily[day] ?? 0];
    final goalList = [for (final day in days) goals.stepsFor(day)];
    final met = [
      for (var i = 0; i < n; i++)
        if (values[i] >= goalList[i]) i,
    ].length;
    // Today is still filling, so the average uses finished days.
    final past = values.take(n - 1).where((v) => v > 0).toList();
    final avg = past.isEmpty ? 0 : past.reduce((a, b) => a + b) / past.length;
    final weekendGoal = goals.weekendSteps;
    return [
      MetricText([(thousands(avg), ' /day')], style: t.hero),
      const SizedBox(height: Space.xs),
      Text('Goal met $met of the last $n days', style: t.small),
      const SizedBox(height: Space.l),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.m,
          children: [
            GoalBars(
              values: values,
              goals: goalList,
              colors: p.steps,
              today: n - 1,
              showGoalLine: true,
              height: 150,
              labels: [
                for (final (i, day) in days.indexed)
                  n <= 7
                      ? weekdayInitial(day)
                      : (n - 1 - i) % 7 == 0
                      ? '${day.day}'
                      : '',
              ],
              format: thousands,
              semanticsLabel:
                  'Daily steps for the last $n days, goal met on $met',
            ),
            Wrap(
              spacing: Space.m,
              runSpacing: Space.xs,
              children: [
                LegendItem(p.steps.main, 'Met'),
                LegendItem(p.steps.dim, 'Not met'),
                Text(
                  weekendGoal == null
                      ? '– – Goal'
                      : '– – Goal (${thousands(weekendGoal)} weekends)',
                  style: t.chart,
                ),
              ],
            ),
          ],
        ),
      ),
      detailGap,
      ..._bests(context, d, goals),
    ];
  }

  List<Widget> _weeks(BuildContext context, StepsData d, Goals goals) {
    final p = context.palette;
    final t = context.type;
    final from = DateTime(d.today.year, d.today.month, d.today.day - 90);
    final avgs = weeklyAverages(d.daily, from, d.today);
    final mondays = [
      for (var i = 0; i < avgs.length; i++)
        DateTime(
          weekStart(from).year,
          weekStart(from).month,
          weekStart(from).day + i * 7,
        ),
    ];
    double weekGoal(DateTime monday) =>
        [
          for (var i = 0; i < 7; i++)
            goals.stepsFor(DateTime(monday.year, monday.month, monday.day + i)),
        ].reduce((a, b) => a + b) /
        7;
    final inRange = [
      for (var i = 0; i < 91; i++)
        ?d.daily[DateTime(d.today.year, d.today.month, d.today.day - i)],
    ];
    final avg = inRange.isEmpty
        ? 0
        : inRange.reduce((a, b) => a + b) / inRange.length;
    return [
      MetricText([(thousands(avg), ' /day')], style: t.hero),
      const SizedBox(height: Space.xs),
      Text('Weekly averages over 13 weeks', style: t.small),
      const SizedBox(height: Space.l),
      GlassCard(
        child: GoalBars(
          values: avgs,
          goals: [for (final m in mondays) weekGoal(m)],
          colors: p.steps,
          today: avgs.length - 1,
          showGoalLine: true,
          height: 150,
          labels: [
            for (final (i, m) in mondays.indexed)
              i % 4 == 0 ? shortDate(m) : '',
          ],
          format: thousands,
          semanticsLabel: 'Average daily steps per week, last 13 weeks',
        ),
      ),
      detailGap,
      ..._bests(context, d, goals),
    ];
  }

  List<Widget> _year(BuildContext context, StepsData d, Goals goals) {
    final p = context.palette;
    final t = context.type;
    final days = d.daily.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (days.isEmpty) {
      return [Text('No step history yet.', style: t.bodyMuted)];
    }
    final total = days.fold<int>(0, (a, e) => a + e.value);
    final metDays = days.where((e) => e.value >= goals.stepsFor(e.key)).length;
    final byMonth = <int, List<int>>{};
    for (final e in days) {
      byMonth
          .putIfAbsent(e.key.year * 12 + e.key.month - 1, () => [])
          .add(e.value);
    }
    final bestMonth = byMonth.entries.reduce(
      (a, b) =>
          a.value.reduce((x, y) => x + y) / a.value.length >=
              b.value.reduce((x, y) => x + y) / b.value.length
          ? a
          : b,
    );
    final levels = {
      for (final e in days)
        e.key: e.value >= goals.stepsFor(e.key)
            ? 1.0
            : e.value / goals.stepsFor(e.key) * 0.75,
    };
    return [
      MetricText([(compact(total), ' steps')], style: t.hero),
      const SizedBox(height: Space.xs),
      Text(
        'Since ${shortDate(days.first.key)} · goal met on $metDays of ${days.length} days',
        style: t.small,
      ),
      const SizedBox(height: Space.l),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Space.m,
          children: [
            Heatmap(
              levels: levels,
              end: d.today,
              colors: p.steps,
              semanticsLabel:
                  'Steps for each day of the last year, goal met on $metDays days',
            ),
            Row(
              spacing: 4,
              children: [
                Text('Less', style: t.chart),
                LegendItem(p.line, ''),
                for (final a in Heatmap.steps)
                  LegendItem(p.steps.main.withValues(alpha: a), ''),
                Text('More', style: t.chart),
              ],
            ),
          ],
        ),
      ),
      detailGap,
      GlassCard(
        child: Row(
          children: [
            _Kv(thousands(total / days.length), 'Daily avg'),
            _Kv(monthShort(bestMonth.key % 12 + 1), 'Best month'),
            _Kv('${(metDays / days.length * 100).round()}%', 'Goal days'),
          ],
        ),
      ),
      if (ref.watch(dataModeProvider) == DataMode.healthConnect) ...[
        detailGap,
        Text(
          'Empty cells are days before your history begins. Health Connect '
          'shares about 30 days from before the app was installed.',
          style: t.small.copyWith(color: p.ink3),
        ),
      ],
    ];
  }

  List<Widget> _bests(BuildContext context, StepsData d, Goals goals) {
    final p = context.palette;
    final day = bestDay(d.daily);
    final week = weeklyTotals(d.daily).entries.fold<MapEntry<DateTime, int>?>(
      null,
      (b, e) => b == null || e.value > b.value ? e : b,
    );
    final longest = streaks(d.daily, goals.stepsFor, d.today).longest;
    if (day == null || week == null) return const [];
    return [
      const GroupLabel('Personal bests'),
      RowList(
        rows: [
          InfoRow(
            icon: Icons.star_rounded,
            iconColor: p.steps.main,
            label: 'Best day',
            detail: dayAndDate(day.key),
            value: thousands(day.value),
          ),
          InfoRow(
            icon: Icons.star_rounded,
            iconColor: p.steps.main,
            label: 'Best week',
            detail: dateRange(
              week.key,
              DateTime(week.key.year, week.key.month, week.key.day + 6),
            ),
            value: thousands(week.value),
          ),
          InfoRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: p.steps.main,
            label: 'Longest streak',
            value: '${math.max(longest, 0)} days',
          ),
        ],
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });
  final IconData icon;
  final String label;
  final List<(String, String)>? value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.s,
        children: [
          Row(
            spacing: 6,
            children: [
              Icon(icon, size: 16, color: p.steps.main),
              Text(label, style: t.label),
            ],
          ),
          if (value case final v?)
            MetricText(v)
          else
            Text('—', style: t.metric.copyWith(color: p.ink3)),
          Text(note, style: t.small),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value, style: context.type.metricSmall),
        Text(label, style: context.type.small),
      ],
    ),
  );
}
