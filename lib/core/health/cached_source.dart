import 'health_data_source.dart';

/// Wraps a source and remembers past days' hourly steps, which only change
/// if a late sync arrives. Today is always read live. This cuts a Home
/// refresh from about 340 Health Connect calls to about 24.
// ponytail: key-value cache until drift lands; move it into the daily tables then.
class CachedHourlySource implements HealthDataSource {
  CachedHourlySource(
    this._inner, {
    required this.read,
    required this.write,
    required this._clock,
  });

  final HealthDataSource _inner;
  final String? Function(String key) read;
  final void Function(String key, String value) write;
  final DateTime Function() _clock;

  static String _key(DateTime d) => 'hourly.${d.year}-${d.month}-${d.day}';

  @override
  Future<List<int>> hourlySteps(DateTime day) async {
    final d = dayOf(day);
    final today = dayOf(_clock());
    // Yesterday can still change if the band syncs late in the morning.
    final settled = d.isBefore(
      DateTime(today.year, today.month, today.day - 1),
    );
    if (settled) {
      final hit = read(_key(d));
      if (hit != null) return hit.split(',').map(int.parse).toList();
    }
    final hours = await _inner.hourlySteps(d);
    if (settled) write(_key(d), hours.join(','));
    return hours;
  }

  @override
  Future<Set<Metric>> supportedMetrics() => _inner.supportedMetrics();
  @override
  Future<DateTime?> lastSync() => _inner.lastSync();
  @override
  Future<DailySeries<int>> dailySteps(DateTime from, DateTime to) =>
      _inner.dailySteps(from, to);
  @override
  Future<DailySeries<int>> activeMinutes(DateTime from, DateTime to) =>
      _inner.activeMinutes(from, to);
  @override
  Future<List<SleepSession>> sleepSessions(DateTime from, DateTime to) =>
      _inner.sleepSessions(from, to);
  @override
  Future<DailySeries<int>> restingHeartRate(DateTime from, DateTime to) =>
      _inner.restingHeartRate(from, to);
  @override
  Future<DailySeries<double>> hrv(DateTime from, DateTime to) =>
      _inner.hrv(from, to);
  @override
  Future<DailySeries<double>> spo2(DateTime from, DateTime to) =>
      _inner.spo2(from, to);
}
