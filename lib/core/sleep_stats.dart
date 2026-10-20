/// Summaries over nights of sleep. Pure functions.
library;

import 'health/health_data_source.dart';

/// Time short of [target], summed over [nights]. Longer nights don't
/// pay the debt back.
Duration sleepDebt(Iterable<SleepSession> nights, Duration target) =>
    nights.fold(
      Duration.zero,
      (debt, n) => n.asleep < target ? debt + (target - n.asleep) : debt,
    );

/// Minutes after noon, so bedtimes either side of midnight compare cleanly.
int minutesAfterNoon(DateTime t) => ((t.hour - 12) % 24) * 60 + t.minute;

/// Average distance of each bedtime from the mean bedtime. Null for fewer
/// than two nights.
Duration? bedtimeSpread(Iterable<SleepSession> nights) {
  final m = nights.map((n) => minutesAfterNoon(n.start)).toList();
  if (m.length < 2) return null;
  final mean = m.reduce((a, b) => a + b) / m.length;
  final spread = m.map((v) => (v - mean).abs()).reduce((a, b) => a + b);
  return Duration(minutes: (spread / m.length).round());
}

/// Time in each stage, in [SleepStage] order.
Map<SleepStage, Duration> stageTotals(Iterable<SleepSegment> segments) => {
  for (final s in SleepStage.values)
    s: segments
        .where((g) => g.stage == s)
        .fold(Duration.zero, (a, g) => a + g.duration),
};
