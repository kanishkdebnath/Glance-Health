import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/baseline.dart';
import '../../core/goals.dart';
import '../../core/health/health_data_source.dart';
import '../../core/pace.dart';
import 'headline.dart';

/// Today's value of one metric, how it compares with the user's usual,
/// and the last 7 days for a sparkline.
class MetricSnapshot<T> {
  const MetricSnapshot({
    required this.today,
    required this.status,
    required this.week,
    this.usual,
  });
  final Reading<T> today;
  final BaselineStatus status;
  final List<num> week;
  final UsualRange? usual;

  Map<String, Object?> toJson(Object? Function(T) encode) => {
    'today': _readingToJson(today, encode),
    'status': status.name,
    'week': week,
    'usual': usual == null ? null : [usual!.low, usual!.high],
  };

  static MetricSnapshot<T> fromJson<T>(
    Map<String, Object?> j,
    T Function(Object?) decode,
  ) {
    final u = j['usual'] as List?;
    return MetricSnapshot(
      today: _readingFromJson(j['today'], decode),
      status: BaselineStatus.values.byName(j['status']! as String),
      week: (j['week']! as List).cast<num>(),
      usual: u == null
          ? null
          : UsualRange((u[0] as num).toDouble(), (u[1] as num).toDouble()),
    );
  }
}

Object? _readingToJson<T>(Reading<T> r, Object? Function(T) encode) =>
    switch (r) {
      Value(:final value) => {'v': encode(value)},
      NoData() => 'none',
      Unsupported() => 'unsupported',
    };

Reading<T> _readingFromJson<T>(Object? j, T Function(Object?) decode) =>
    switch (j) {
      'none' => NoData<T>(),
      'unsupported' => Unsupported<T>(),
      _ => Value(decode((j! as Map)['v'])),
    };

int _int(Object? v) => (v! as num).toInt();
double _double(Object? v) => (v! as num).toDouble();

class HomeSummary {
  const HomeSummary({
    required this.date,
    required this.syncedAt,
    required this.steps,
    required this.stepGoal,
    required this.usualFraction,
    required this.progress,
    required this.sleep,
    required this.restingHr,
    required this.activeMinutes,
    required this.hrv,
    required this.spo2,
    required this.headline,
  });

  final DateTime date;
  final DateTime? syncedAt;
  final int steps;
  final int stepGoal;
  final double? usualFraction;
  final StepProgress progress;
  final MetricSnapshot<Duration> sleep;
  final MetricSnapshot<int> restingHr;
  final Reading<int> activeMinutes;
  final Reading<double> hrv;
  final Reading<double> spo2;
  final String headline;

  Map<String, Object?> toJson() => {
    'date': date.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
    'steps': steps,
    'stepGoal': stepGoal,
    'usualFraction': usualFraction,
    'progress': progress.name,
    'sleep': sleep.toJson((d) => d.inMinutes),
    'restingHr': restingHr.toJson((v) => v),
    'activeMinutes': _readingToJson(activeMinutes, (v) => v),
    'hrv': _readingToJson(hrv, (v) => v),
    'spo2': _readingToJson(spo2, (v) => v),
    'headline': headline,
  };

  factory HomeSummary.fromJson(Map<String, Object?> j) => HomeSummary(
    date: DateTime.parse(j['date']! as String),
    syncedAt: j['syncedAt'] == null
        ? null
        : DateTime.parse(j['syncedAt']! as String),
    steps: _int(j['steps']),
    stepGoal: _int(j['stepGoal']),
    usualFraction: (j['usualFraction'] as num?)?.toDouble(),
    progress: StepProgress.values.byName(j['progress']! as String),
    sleep: MetricSnapshot.fromJson(
      j['sleep']! as Map<String, Object?>,
      (v) => Duration(minutes: _int(v)),
    ),
    restingHr: MetricSnapshot.fromJson(
      j['restingHr']! as Map<String, Object?>,
      _int,
    ),
    activeMinutes: _readingFromJson(j['activeMinutes'], _int),
    hrv: _readingFromJson(j['hrv'], _double),
    spo2: _readingFromJson(j['spo2'], _double),
    headline: j['headline']! as String,
  );
}

/// Sample and real data are cached separately so one never shows as the other.
String _cacheKey(DataMode mode) => 'home.v1.${mode.name}';

/// The last Home summary saved on this phone, shown instantly on launch
/// while fresh data loads. Null on first launch or if the format changed.
final cachedHomeSummaryProvider = Provider<HomeSummary?>((ref) {
  final raw = ref
      .watch(prefsProvider)
      .getString(_cacheKey(ref.watch(dataModeProvider)));
  if (raw == null) return null;
  try {
    return HomeSummary.fromJson(jsonDecode(raw) as Map<String, Object?>);
  } catch (_) {
    return null; // Saved by an older version; the fresh load replaces it.
  }
});

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final mode = ref.watch(dataModeProvider);
  final summary = await loadHomeSummary(
    ref.watch(healthSourceProvider),
    ref.watch(goalsProvider),
    ref.watch(clockProvider)(),
  );
  await ref
      .read(prefsProvider)
      .setString(_cacheKey(mode), jsonEncode(summary.toJson()));
  return summary;
});

Future<HomeSummary> loadHomeSummary(
  HealthDataSource src,
  Goals goals,
  DateTime now,
) async {
  final today = dayOf(now);
  DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);
  final from = daysAgo(baselineWindowDays);

  final supported = await src.supportedMetrics();
  final steps = (await src.dailySteps(today, today))[today] ?? 0;
  final pastHours = await Future.wait([
    for (var i = 1; i <= 14; i++) src.hourlySteps(daysAgo(i)),
  ]);
  final usual = usualFractionBy(pastHours, now);
  final goal = goals.stepsFor(today);
  final progress = stepProgress(steps: steps, goal: goal, usualFraction: usual);

  final sleepByDay = {
    for (final s in await src.sleepSessions(from, today))
      s.day: s.asleep.inMinutes,
  };
  final sleep = _snapshot<Duration>(
    supported.contains(Metric.sleep),
    sleepByDay,
    today,
    (m) => Duration(minutes: m.round()),
    weekScale: 1 / 60,
  );
  final restingHr = _snapshot<int>(
    supported.contains(Metric.restingHeartRate),
    await src.restingHeartRate(from, today),
    today,
    (v) => v.round(),
  );

  Reading<T> todayOf<T>(Metric m, DailySeries<T> s) => !supported.contains(m)
      ? Unsupported<T>()
      : (s[today] == null ? NoData<T>() : Value(s[today] as T));

  return HomeSummary(
    date: today,
    syncedAt: await src.lastSync(),
    steps: steps,
    stepGoal: goal,
    usualFraction: usual,
    progress: progress,
    sleep: sleep,
    restingHr: restingHr,
    activeMinutes: todayOf(
      Metric.activeMinutes,
      await src.activeMinutes(today, today),
    ),
    hrv: todayOf(Metric.hrv, await src.hrv(today, today)),
    spo2: todayOf(Metric.spo2, await src.spo2(today, today)),
    headline: homeHeadline(
      steps: progress,
      sleep: sleep.today is Value ? sleep.status : null,
      restingHr: restingHr.today is Value ? restingHr.status : null,
    ),
  );
}

MetricSnapshot<T> _snapshot<T>(
  bool supported,
  DailySeries<num> series,
  DateTime today,
  T Function(num) wrap, {
  double weekScale = 1,
}) {
  if (!supported) {
    return MetricSnapshot(
      today: Unsupported<T>(),
      status: BaselineStatus.learning,
      week: const [],
    );
  }
  final value = series[today];
  final history = [
    for (final e in series.entries)
      if (e.key.isBefore(today)) e.value,
  ];
  final days = series.keys.toList()..sort();
  final week = [
    for (final d in days.skip(days.length > 7 ? days.length - 7 : 0))
      series[d]! * weekScale,
  ];
  return MetricSnapshot(
    today: value == null ? NoData<T>() : Value(wrap(value)),
    status: value == null
        ? BaselineStatus.learning
        : compareToUsual(value, history),
    week: week,
    usual: usualRange(history),
  );
}
