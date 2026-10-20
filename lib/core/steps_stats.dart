/// Streaks, bests and summaries over daily step totals. Pure functions.
library;

import 'health/health_data_source.dart';

typedef GoalFor = int Function(DateTime day);

DateTime _addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Monday of the week [d] falls in.
DateTime weekStart(DateTime d) => _addDays(dayOf(d), 1 - d.weekday);

class Streaks {
  const Streaks({
    required this.current,
    required this.longest,
    required this.graceLeft,
  });

  /// Goal days in the run that reaches today (or yesterday, while today's
  /// goal isn't met yet).
  final int current;
  final int longest;

  /// Missed days the current week can still absorb (0 or 1).
  final int graceLeft;
}

/// One missed day per Monday–Sunday week doesn't break a streak; the grace
/// day itself isn't counted. Days with no data count as missed. Today only
/// counts once its goal is met, so an unfinished day never breaks a run.
Streaks streaks(DailySeries<int> daily, GoalFor goalFor, DateTime today) {
  final days = daily.keys.where((d) => d.isBefore(today)).toList()..sort();
  final todayMet =
      (daily[today] ?? 0) >= goalFor(today) && daily[today] != null;
  var run = 0, longest = 0;
  final graceUsed = <DateTime>{};
  if (days.isNotEmpty) {
    for (var d = days.first; d.isBefore(today); d = _addDays(d, 1)) {
      if ((daily[d] ?? 0) >= goalFor(d) && daily[d] != null) {
        run++;
      } else if (graceUsed.add(weekStart(d))) {
        // Grace day: the run carries on.
      } else {
        run = 0;
      }
      if (run > longest) longest = run;
    }
  }
  if (todayMet) run++;
  if (run > longest) longest = run;
  return Streaks(
    current: run,
    longest: longest,
    graceLeft: graceUsed.contains(weekStart(today)) ? 0 : 1,
  );
}

/// The day with the most steps.
MapEntry<DateTime, int>? bestDay(DailySeries<int> daily) =>
    daily.entries.fold<MapEntry<DateTime, int>?>(
      null,
      (best, e) => best == null || e.value > best.value ? e : best,
    );

/// Monday–Sunday totals, keyed by Monday.
Map<DateTime, int> weeklyTotals(DailySeries<int> daily) {
  final out = <DateTime, int>{};
  for (final e in daily.entries) {
    out.update(weekStart(e.key), (v) => v + e.value, ifAbsent: () => e.value);
  }
  return out;
}

/// Mean steps per day with data, for each week from [from] to [to].
List<double> weeklyAverages(
  DailySeries<int> daily,
  DateTime from,
  DateTime to,
) {
  final out = <double>[];
  for (var w = weekStart(from); !w.isAfter(to); w = _addDays(w, 7)) {
    final v = [for (var i = 0; i < 7; i++) ?daily[_addDays(w, i)]];
    out.add(v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length);
  }
  return out;
}

/// Steps the user has usually taken by [now], averaged over past days'
/// hourly buckets. Null without history.
int? usualStepsBy(List<List<int>> pastDays, DateTime now) {
  final totals = [
    for (final hours in pastDays)
      if (hours.any((h) => h > 0))
        [for (var h = 0; h < now.hour; h++) hours[h]].fold(0, (a, b) => a + b) +
            hours[now.hour] * now.minute / 60,
  ];
  if (totals.isEmpty) return null;
  return (totals.reduce((a, b) => a + b) / totals.length).round();
}
