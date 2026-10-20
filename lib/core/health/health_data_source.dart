/// Where health data comes from. The real implementation reads Health
/// Connect (Android) or Apple Health (iOS); the mock serves sample data for
/// development and tests. Screens never talk to a source directly; they go
/// through providers.
///
/// Workouts and strength logs will arrive as their own source and models
/// rather than growing this interface.
library;

/// Every metric the app knows about. Used to report what a device provides.
enum Metric {
  steps,
  activeMinutes,
  sleep,
  restingHeartRate,
  heartRateRange,
  hrv,
  spo2,
  cycle,
}

/// Values keyed by local midnight of the day they belong to.
typedef DailySeries<T> = Map<DateTime, T>;

/// A value that may be missing for two different reasons. The UI shows
/// "Not available from your device" for [Unsupported] and a "no data yet"
/// state for [NoData].
sealed class Reading<T> {
  const Reading();
  T? get valueOrNull => switch (this) {
    Value<T>(:final value) => value,
    _ => null,
  };
}

final class Value<T> extends Reading<T> {
  const Value(this.value);
  final T value;
}

final class NoData<T> extends Reading<T> {
  const NoData();
}

final class Unsupported<T> extends Reading<T> {
  const Unsupported();
}

enum SleepStage { awake, rem, light, deep }

class SleepSegment {
  const SleepSegment(this.stage, this.start, this.end);
  final SleepStage stage;
  final DateTime start;
  final DateTime end;
  Duration get duration => end.difference(start);
}

class SleepSession {
  const SleepSession({
    required this.start,
    required this.end,
    required this.asleep,
    this.segments = const [],
  });
  final DateTime start;
  final DateTime end;
  final Duration asleep;
  final List<SleepSegment> segments;

  Duration get inBed => end.difference(start);

  /// Sessions belong to the day they end on.
  DateTime get day => DateTime(end.year, end.month, end.day);
}

abstract interface class HealthDataSource {
  Future<Set<Metric>> supportedMetrics();
  Future<DateTime?> lastSync();

  /// Inclusive day range, both at local midnight.
  Future<DailySeries<int>> dailySteps(DateTime from, DateTime to);

  /// 24 hourly buckets for one day.
  Future<List<int>> hourlySteps(DateTime day);
  Future<DailySeries<int>> activeMinutes(DateTime from, DateTime to);
  Future<List<SleepSession>> sleepSessions(DateTime from, DateTime to);
  Future<DailySeries<int>> restingHeartRate(DateTime from, DateTime to);
  Future<DailySeries<double>> hrv(DateTime from, DateTime to);
  Future<DailySeries<double>> spo2(DateTime from, DateTime to);
}

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);
