import 'dart:math';

import 'health_data_source.dart';

/// Deterministic sample data shaped like a Fitbit Air user. The last week
/// matches the numbers in the design document.
class MockHealthDataSource implements HealthDataSource {
  MockHealthDataSource({DateTime Function()? clock, Set<Metric>? supported})
    : _clock = clock ?? DateTime.now,
      _supported = supported ?? Metric.values.toSet();

  final DateTime Function() _clock;
  final Set<Metric> _supported;

  // A typical day's walking, by hour. Sums to about 6,460 by 4 pm.
  static const _hourProfile = [
    0,
    0,
    0,
    0,
    0,
    0,
    40,
    820,
    1140,
    310,
    260,
    420,
    980,
    640,
    520,
    1330,
    900,
    760,
    640,
    380,
    180,
    60,
    0,
    0,
  ];
  static const _recentSteps = [
    9120,
    7340,
    10450,
    7810,
    5200,
    8230,
  ]; // 6 days ago … yesterday
  static const _recentSleepHours = [
    6.9,
    7.4,
    6.2,
    8.1,
    8.4,
    7.0,
  ]; // 7 nights ago … 2 nights ago
  static const _recentRhr = [62, 61, 62, 60, 61, 59, 58]; // 6 days ago … today

  DateTime get _today => dayOf(_clock());
  // UTC dates so daylight-saving changes don't shift the count.
  int _ago(DateTime day) => DateTime.utc(
    _today.year,
    _today.month,
    _today.day,
  ).difference(DateTime.utc(day.year, day.month, day.day)).inDays;
  Random _rng(DateTime day, int salt) =>
      Random(day.year * 10000 + day.month * 100 + day.day + salt);

  Iterable<DateTime> _days(DateTime from, DateTime to) sync* {
    for (
      var d = dayOf(from);
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      if (!d.isAfter(_today)) yield d;
    }
  }

  DailySeries<T> _series<T>(
    Metric m,
    DateTime from,
    DateTime to,
    T Function(DateTime day, int ago) f,
  ) => _supported.contains(m)
      ? {for (final d in _days(from, to)) d: f(d, _ago(d))}
      : {};

  @override
  Future<Set<Metric>> supportedMetrics() async => _supported;

  @override
  Future<DateTime?> lastSync() async =>
      _clock().subtract(const Duration(minutes: 7));

  @override
  Future<List<int>> hourlySteps(DateTime day) async {
    if (!_supported.contains(Metric.steps)) return List.filled(24, 0);
    if (_ago(day) == 0) return _todayHourly();
    final scale =
        (await dailySteps(day, day))[dayOf(day)]! / 9380; // profile total
    final r = _rng(day, 1);
    return [
      for (final v in _hourProfile)
        (v * scale * (0.8 + r.nextDouble() * 0.4)).round(),
    ];
  }

  @override
  Future<DailySeries<int>> dailySteps(DateTime from, DateTime to) async {
    final todayTotal = (await _todayHourly()).fold(0, (a, b) => a + b);
    return _series(Metric.steps, from, to, (d, ago) {
      if (ago == 0) return todayTotal;
      if (ago <= 6) return _recentSteps[6 - ago];
      return 4500 + _rng(d, 2).nextInt(7000);
    });
  }

  Future<List<int>> _todayHourly() async {
    final now = _clock();
    return [
      for (var h = 0; h < 24; h++)
        h < now.hour
            ? _hourProfile[h]
            : (h == now.hour ? (_hourProfile[h] * now.minute / 60).round() : 0),
    ];
  }

  @override
  Future<DailySeries<int>> activeMinutes(DateTime from, DateTime to) async =>
      _series(
        Metric.activeMinutes,
        from,
        to,
        (d, ago) => ago == 0 ? 34 : 10 + _rng(d, 3).nextInt(45),
      );

  @override
  Future<List<SleepSession>> sleepSessions(DateTime from, DateTime to) async {
    if (!_supported.contains(Metric.sleep)) return [];
    return [
      for (final d in _days(from, to))
        if (_ago(d) == 0) _lastNight(d) else _night(d, _ago(d)),
    ];
  }

  SleepSession _night(DateTime wakeDay, int ago) {
    final hours = ago <= 6
        ? _recentSleepHours[6 - ago]
        : 6.3 + _rng(wakeDay, 4).nextDouble() * 1.9;
    final asleep = Duration(minutes: (hours * 60).round());
    final start = DateTime(
      wakeDay.year,
      wakeDay.month,
      wakeDay.day - 1,
      23,
      10 + _rng(wakeDay, 5).nextInt(50),
    );
    return SleepSession(
      start: start,
      end: start.add(asleep + const Duration(minutes: 22)),
      asleep: asleep,
    );
  }

  SleepSession _lastNight(DateTime today) {
    final start = DateTime(today.year, today.month, today.day - 1, 23, 35);
    const plan = [
      (SleepStage.awake, 8),
      (SleepStage.light, 22),
      (SleepStage.deep, 45),
      (SleepStage.light, 35),
      (SleepStage.rem, 20),
      (SleepStage.light, 30),
      (SleepStage.deep, 35),
      (SleepStage.light, 37),
      (SleepStage.rem, 30),
      (SleepStage.awake, 6),
      (SleepStage.light, 32),
      (SleepStage.deep, 22),
      (SleepStage.light, 38),
      (SleepStage.rem, 42),
      (SleepStage.light, 28),
      (SleepStage.rem, 22),
      (SleepStage.awake, 10),
    ];
    final segments = <SleepSegment>[];
    var t = start;
    for (final (stage, minutes) in plan) {
      final end = t.add(Duration(minutes: minutes));
      segments.add(SleepSegment(stage, t, end));
      t = end;
    }
    return SleepSession(
      start: start,
      end: t,
      asleep: const Duration(hours: 7, minutes: 18),
      segments: segments,
    );
  }

  @override
  Future<DailySeries<int>> restingHeartRate(DateTime from, DateTime to) async =>
      _series(
        Metric.restingHeartRate,
        from,
        to,
        (d, ago) => ago <= 6 ? _recentRhr[6 - ago] : 60 + _rng(d, 6).nextInt(5),
      );

  @override
  Future<DailySeries<HeartRange>> heartRateRange(
    DateTime from,
    DateTime to,
  ) async {
    final rhr = await restingHeartRate(from, to);
    return _series(Metric.heartRateRange, from, to, (d, ago) {
      final r = _rng(d, 9);
      return (
        min: (rhr[d] ?? 60) - 4 - r.nextInt(3),
        max: ago == 0 ? 138 : 110 + r.nextInt(45),
      );
    });
  }

  @override
  Future<DailySeries<double>> hrv(DateTime from, DateTime to) async => _series(
    Metric.hrv,
    from,
    to,
    (d, ago) => ago == 0 ? 46.0 : 38 + _rng(d, 7).nextDouble() * 10,
  );

  @override
  Future<DailySeries<double>> spo2(DateTime from, DateTime to) async => _series(
    Metric.spo2,
    from,
    to,
    (d, ago) => ago == 0 ? 96.0 : 95 + _rng(d, 8).nextInt(3).toDouble(),
  );
}
