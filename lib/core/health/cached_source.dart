import 'health_data_source.dart';

/// Wraps a source and remembers settled days' hourly steps and heart-rate
/// ranges, which only change if a late sync arrives. Recent days are always
/// read live.
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

  /// Yesterday can still change if the band syncs late in the morning.
  bool _settled(DateTime d) {
    final today = dayOf(_clock());
    return d.isBefore(DateTime(today.year, today.month, today.day - 1));
  }

  @override
  Future<List<int>> hourlySteps(DateTime day) async {
    final d = dayOf(day);
    final settled = _settled(d);
    if (settled) {
      final hit = read(_key(d));
      if (hit != null) return hit.split(',').map(int.parse).toList();
    }
    final hours = await _inner.hourlySteps(d);
    if (settled) write(_key(d), hours.join(','));
    return hours;
  }

  /// Cached as "min,max", or "" for a settled day with no heart rate.
  @override
  Future<DailySeries<HeartRange>> heartRateRange(
    DateTime from,
    DateTime to,
  ) async {
    final out = <DateTime, HeartRange>{};
    for (
      var d = dayOf(from);
      !d.isAfter(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final key = 'hrRange.${d.year}-${d.month}-${d.day}';
      final hit = _settled(d) ? read(key) : null;
      if (hit != null) {
        if (hit.isNotEmpty) {
          final [lo, hi] = hit.split(',').map(int.parse).toList();
          out[d] = (min: lo, max: hi);
        }
        continue;
      }
      final r = (await _inner.heartRateRange(d, d))[d];
      if (r != null) out[d] = r;
      if (_settled(d)) write(key, r == null ? '' : '${r.min},${r.max}');
    }
    return out;
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
