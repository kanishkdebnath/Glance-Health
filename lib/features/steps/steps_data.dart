import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/health/health_data_source.dart';
import '../../core/steps_stats.dart';

/// Everything the Steps tab shows, for every range. Goals are read
/// separately so editing a goal doesn't reload a year of data.
class StepsData {
  const StepsData({
    required this.now,
    required this.daily,
    required this.todayHours,
    required this.usualByNow,
    required this.activeToday,
    required this.activeWeek,
  });

  final DateTime now;

  /// About a year of daily totals, today included. Days without steps are
  /// missing, not zero.
  final DailySeries<int> daily;
  final List<int> todayHours;
  final int? usualByNow;
  final Reading<int> activeToday;
  final int? activeWeek;

  DateTime get today => dayOf(now);
}

/// Days of history the Year view covers.
const yearDays = 371; // 53 weeks

final stepsDataProvider = FutureProvider<StepsData>((ref) async {
  final src = ref.watch(healthSourceProvider);
  final now = ref.watch(clockProvider)();
  final today = dayOf(now);
  DateTime ago(int n) => DateTime(today.year, today.month, today.day - n);

  final supported = await src.supportedMetrics();
  final daily = await src.dailySteps(ago(yearDays - 1), today);
  final todayHours = await src.hourlySteps(today);
  final past = await Future.wait([
    for (var i = 1; i <= 14; i++) src.hourlySteps(ago(i)),
  ]);
  final active = await src.activeMinutes(weekStart(today), today);

  return StepsData(
    now: now,
    daily: daily,
    todayHours: todayHours,
    usualByNow: usualStepsBy(past, now),
    activeToday: !supported.contains(Metric.activeMinutes)
        ? const Unsupported()
        : active[today] == null
        ? const NoData()
        : Value(active[today]!),
    activeWeek: supported.contains(Metric.activeMinutes)
        ? active.values.fold<int>(0, (a, b) => a + b)
        : null,
  );
});
