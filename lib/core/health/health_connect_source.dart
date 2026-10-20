import 'dart:math' as math;

import 'package:health/health.dart';

import 'health_data_source.dart';

/// Everything the app reads from Health Connect / Apple Health. Read only.
const readTypes = [
  HealthDataType.STEPS,
  HealthDataType.SLEEP_SESSION,
  HealthDataType.HEART_RATE,
  HealthDataType.RESTING_HEART_RATE,
  HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.WORKOUT,
  HealthDataType.MENSTRUATION_FLOW,
];

const _stageTypes = {
  HealthDataType.SLEEP_AWAKE: SleepStage.awake,
  HealthDataType.SLEEP_AWAKE_IN_BED: SleepStage.awake,
  HealthDataType.SLEEP_OUT_OF_BED: SleepStage.awake,
  HealthDataType.SLEEP_REM: SleepStage.rem,
  HealthDataType.SLEEP_LIGHT: SleepStage.light,
  HealthDataType.SLEEP_ASLEEP: SleepStage.light,
  HealthDataType.SLEEP_DEEP: SleepStage.deep,
};

enum HealthConnectStatus {
  unavailable,
  updateRequired,
  notConnected,
  connected,
}

/// Checking and requesting access. Separate from reading so settings and
/// onboarding can use it without a data source.
class HealthConnectAccess {
  HealthConnectAccess([Health? health]) : _h = health ?? Health();
  final Health _h;
  Future<void>? _ready;
  Future<void> _init() => _ready ??= _h.configure();

  Future<HealthConnectStatus> status() async {
    await _init();
    final sdk = await _h.getHealthConnectSdkStatus();
    if (sdk == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
      return HealthConnectStatus.updateRequired;
    }
    if (sdk != HealthConnectSdkStatus.sdkAvailable) {
      return HealthConnectStatus.unavailable;
    }
    final granted = await _h.hasPermissions(readTypes);
    return granted == true
        ? HealthConnectStatus.connected
        : HealthConnectStatus.notConnected;
  }

  /// Opens the system permission sheet, then asks for history and
  /// background reads where the device supports them.
  Future<bool> connect() async {
    await _init();
    await _h.requestAuthorization(readTypes);
    // The request's return value can be false even when the user allowed
    // access (seen on Android 16), so check what was actually granted.
    final ok = await _h.hasPermissions(readTypes) == true;
    if (ok) {
      if (await _h.isHealthDataHistoryAvailable() &&
          !await _h.isHealthDataHistoryAuthorized()) {
        await _h.requestHealthDataHistoryAuthorization();
      }
      if (await _h.isHealthDataInBackgroundAvailable() &&
          !await _h.isHealthDataInBackgroundAuthorized()) {
        await _h.requestHealthDataInBackgroundAuthorization();
      }
    }
    return ok;
  }

  Future<void> openStoreListing() async {
    await _init();
    await _h.installHealthConnect();
  }
}

/// Reads Health Connect (Android) or Apple Health (iOS) through the
/// `health` package.
class HealthConnectSource implements HealthDataSource {
  HealthConnectSource({Health? health, DateTime Function()? clock})
    : _h = health ?? Health(),
      _clock = clock ?? DateTime.now;

  final Health _h;
  final DateTime Function() _clock;
  Future<void>? _ready;
  Future<Set<Metric>>? _supported;

  Future<void> _init() => _ready ??= _h.configure();

  Future<List<HealthDataPoint>> _points(
    List<HealthDataType> types,
    DateTime from,
    DateTime to,
  ) async {
    await _init();
    return _h.getHealthDataFromTypes(
      types: types,
      startTime: from,
      endTime: to,
    );
  }

  static DateTime _end(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);
  static num _num(HealthDataPoint p) =>
      (p.value as NumericHealthValue).numericValue;

  /// "Not available from your device" means nothing at all in the last 30
  /// days; "no data" means some history but nothing for today.
  @override
  Future<Set<Metric>> supportedMetrics() => _supported ??= _detectSupported();

  Future<Set<Metric>> _detectSupported() async {
    final today = dayOf(_clock());
    final from = DateTime(today.year, today.month, today.day - 30);
    final to = _end(today);
    Future<bool> has(List<HealthDataType> t, {DateTime? since}) async =>
        (await _points(t, since ?? from, to)).isNotEmpty;
    // Steps and heart rate are high-volume (a watch writes heart rate every
    // few seconds). Reading 30 days of raw samples runs the app out of
    // memory, so use the aggregate for steps and one day for heart rate.
    return {
      if ((await _h.getTotalStepsInInterval(from, to) ?? 0) > 0) Metric.steps,
      if (await has([HealthDataType.SLEEP_SESSION])) Metric.sleep,
      if (await has([HealthDataType.RESTING_HEART_RATE]))
        Metric.restingHeartRate,
      if (await has([
        HealthDataType.HEART_RATE,
      ], since: to.subtract(const Duration(days: 1))))
        Metric.heartRateRange,
      if (await has([HealthDataType.HEART_RATE_VARIABILITY_RMSSD])) Metric.hrv,
      if (await has([HealthDataType.BLOOD_OXYGEN])) Metric.spo2,
      if (await has([HealthDataType.MENSTRUATION_FLOW])) Metric.cycle,
      // Active minutes have no Health Connect record type; they stay
      // "not available" until the spike finds a source for them.
    };
  }

  @override
  Future<DateTime?> lastSync() async {
    final now = _clock();
    final pts = await _points(
      [HealthDataType.STEPS],
      now.subtract(const Duration(days: 1)),
      now,
    );
    if (pts.isEmpty) return null;
    return pts.map((p) => p.dateTo).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Uses Health Connect's own aggregate, which applies the user's app
  /// priority order, so phone and band steps aren't counted twice.
  @override
  Future<DailySeries<int>> dailySteps(DateTime from, DateTime to) async {
    await _init();
    final out = <DateTime, int>{};
    for (
      var d = dayOf(from);
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final total = await _h.getTotalStepsInInterval(d, _end(d));
      if (total != null) out[d] = total;
    }
    return out;
  }

  // ponytail: 24 aggregate calls per day. Cache past days in local storage
  // once drift lands; only today needs a live read.
  @override
  Future<List<int>> hourlySteps(DateTime day) async {
    await _init();
    final now = _clock();
    final start = dayOf(day);
    return [
      for (var h = 0; h < 24; h++)
        if (start.add(Duration(hours: h)).isAfter(now))
          0
        else
          await _h.getTotalStepsInInterval(
                DateTime(start.year, start.month, start.day, h),
                DateTime(start.year, start.month, start.day, h + 1),
              ) ??
              0,
    ];
  }

  @override
  Future<DailySeries<int>> activeMinutes(DateTime from, DateTime to) async =>
      {};

  @override
  Future<List<SleepSession>> sleepSessions(DateTime from, DateTime to) async {
    // Start the evening before so the first night is included.
    final start = DateTime(from.year, from.month, from.day - 1, 12);
    final end = _end(to);
    final sessions = await _points([HealthDataType.SLEEP_SESSION], start, end);
    final stages = await _points(_stageTypes.keys.toList(), start, end);

    final byDay = <DateTime, SleepSession>{};
    for (final s in sessions) {
      final segments = [
        for (final st in stages)
          if (!st.dateFrom.isBefore(s.dateFrom) && !st.dateTo.isAfter(s.dateTo))
            SleepSegment(_stageTypes[st.type]!, st.dateFrom, st.dateTo),
      ]..sort((a, b) => a.start.compareTo(b.start));
      final asleep = segments.isEmpty
          ? s.dateTo.difference(s.dateFrom)
          : segments
                .where((g) => g.stage != SleepStage.awake)
                .fold(Duration.zero, (a, g) => a + g.duration);
      final session = SleepSession(
        start: s.dateFrom,
        end: s.dateTo,
        asleep: asleep,
        segments: segments,
      );
      if (session.day.isBefore(dayOf(from)) || session.day.isAfter(to)) {
        continue;
      }
      // ponytail: when several apps record the same night, keep the longest.
      // Revisit once the spike shows which sources write sleep.
      final existing = byDay[session.day];
      if (existing == null || session.asleep > existing.asleep) {
        byDay[session.day] = session;
      }
    }
    return byDay.values.toList()..sort((a, b) => a.start.compareTo(b.start));
  }

  DailySeries<double> _daily(
    List<HealthDataPoint> pts,
    double Function(List<double>) reduce,
  ) {
    final groups = <DateTime, List<double>>{};
    for (final p in pts..sort((a, b) => a.dateFrom.compareTo(b.dateFrom))) {
      groups.putIfAbsent(dayOf(p.dateFrom), () => []).add(_num(p).toDouble());
    }
    return groups.map((d, v) => MapEntry(d, reduce(v)));
  }

  static double _mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;

  @override
  Future<DailySeries<int>> restingHeartRate(DateTime from, DateTime to) async {
    final pts = await _points(
      [HealthDataType.RESTING_HEART_RATE],
      from,
      _end(to),
    );
    return _daily(pts, (v) => v.last).map((d, v) => MapEntry(d, v.round()));
  }

  @override
  Future<DailySeries<double>> hrv(DateTime from, DateTime to) async => _daily(
    await _points(
      [HealthDataType.HEART_RATE_VARIABILITY_RMSSD],
      from,
      _end(to),
    ),
    _mean,
  );

  @override
  Future<DailySeries<double>> spo2(DateTime from, DateTime to) async {
    final daily = _daily(
      await _points([HealthDataType.BLOOD_OXYGEN], from, _end(to)),
      _mean,
    );
    // Some sources report a 0–1 fraction rather than a percentage.
    return daily.map(
      (d, v) => MapEntry(d, v <= 1 ? v * 100 : math.min(v, 100)),
    );
  }
}
