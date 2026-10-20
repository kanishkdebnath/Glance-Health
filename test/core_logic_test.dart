import 'package:flutter_test/flutter_test.dart';
import 'package:glance_health/core/baseline.dart';
import 'package:glance_health/core/format.dart';
import 'package:glance_health/core/goals.dart';
import 'package:glance_health/core/pace.dart';
import 'package:glance_health/core/health/health_data_source.dart';
import 'package:glance_health/core/sleep_stats.dart';
import 'package:glance_health/core/steps_stats.dart';
import 'package:glance_health/features/home/headline.dart';

void main() {
  group('baseline', () {
    final history = [for (var i = 0; i < 20; i++) 60 + i % 5]; // 60..64

    test('needs 14 days before labelling', () {
      expect(compareToUsual(50, history.take(13)), BaselineStatus.learning);
      expect(usualRange(history.take(13)), isNull);
    });

    test('labels below, typical and above', () {
      expect(compareToUsual(58, history), BaselineStatus.below);
      expect(compareToUsual(62, history), BaselineStatus.typical);
      expect(compareToUsual(66, history), BaselineStatus.above);
    });
  });

  group('pace', () {
    final day = [
      for (var h = 0; h < 24; h++) h >= 8 && h < 20 ? 100 : 0,
    ]; // 1,200 steps, 8am–8pm

    test('usual fraction at 2pm is half the day', () {
      expect(
        usualFractionBy([day, day], DateTime(2026, 10, 20, 14)),
        closeTo(0.5, 1e-9),
      );
    });

    test('progress states', () {
      expect(
        stepProgress(steps: 8000, goal: 8000, usualFraction: 0.5),
        StepProgress.goalMet,
      );
      expect(
        stepProgress(steps: 3900, goal: 8000, usualFraction: 0.5),
        StepProgress.onPace,
      ); // within 5%
      expect(
        stepProgress(steps: 3000, goal: 8000, usualFraction: 0.5),
        StepProgress.behind,
      );
      expect(
        stepProgress(steps: 0, goal: 8000, usualFraction: null),
        StepProgress.noData,
      );
    });
  });

  group('headline', () {
    test('joins sleep and steps', () {
      expect(
        homeHeadline(steps: StepProgress.onPace, sleep: BaselineStatus.typical),
        "You slept about as long as usual and you're on pace for your step goal.",
      );
    });

    test('adds resting heart rate only when it moved', () {
      expect(
        homeHeadline(
          steps: StepProgress.goalMet,
          restingHr: BaselineStatus.below,
        ),
        "You've reached your step goal. Resting heart rate is a little lower than usual.",
      );
      expect(
        homeHeadline(
          steps: StepProgress.behind,
          restingHr: BaselineStatus.typical,
        ),
        "You're a little behind your usual pace.",
      );
    });

    test('falls back when nothing is known', () {
      expect(
        homeHeadline(
          steps: StepProgress.noData,
          sleep: BaselineStatus.learning,
        ),
        "Here's your day so far.",
      );
    });
  });

  group('format and goals', () {
    test('formats', () {
      expect(thousands(6420), '6,420');
      expect(thousands(1234567), '1,234,567');
      expect(hoursMinutes(const Duration(hours: 7, minutes: 18)), '7h 18m');
      expect(clockTime(DateTime(2026, 10, 20, 15, 8)), '3:08 pm');
      expect(clockTime(DateTime(2026, 10, 20, 0, 5)), '12:05 am');
      expect(longDate(DateTime(2026, 10, 20)), 'Tuesday, 20 October');
    });

    test('weekend goal applies on Saturday and Sunday only', () {
      const g = Goals(steps: 8000, weekendSteps: 6000);
      expect(g.stepsFor(DateTime(2026, 10, 17)), 6000); // Saturday
      expect(g.stepsFor(DateTime(2026, 10, 19)), 8000); // Monday
    });
  });

  group('step streaks', () {
    // Monday 5 to Tuesday 20 October 2026; today is the 20th.
    final today = DateTime(2026, 10, 20);
    DateTime day(int d) => DateTime(2026, 10, d);
    int goal(DateTime _) => 8000;
    DailySeries<int> days(Map<int, int> m) =>
        m.map((d, v) => MapEntry(day(d), v));

    test('counts met days and skips an unfinished today', () {
      final s = streaks(
        days({15: 9000, 16: 9000, 17: 9000, 18: 9000, 19: 9000, 20: 300}),
        goal,
        today,
      );
      expect(s.current, 5);
      expect(s.graceLeft, 1);
    });

    test('one missed day a week is forgiven, the second breaks the run', () {
      // Week of 12 Oct: miss on 13th (grace), miss on 15th (break).
      final s = streaks(
        days({
          12: 9000,
          13: 100,
          14: 9000,
          15: 100,
          16: 9000,
          17: 9000,
          18: 9000,
        }),
        goal,
        today,
      );
      expect(
        s.current,
        3,
      ); // 16, 17, 18; 19 is missing and uses this week's grace
      expect(s.longest, 3);
      expect(s.graceLeft, 0);
    });

    test('today counts once met', () {
      final s = streaks(days({19: 9000, 20: 8000}), goal, today);
      expect(s.current, 2);
    });
  });

  group('step summaries', () {
    final daily = {
      DateTime(2026, 10, 12): 1000, // Monday
      DateTime(2026, 10, 13): 3000,
      DateTime(2026, 10, 19): 5000, // next Monday
    };

    test('best day and weekly totals', () {
      expect(bestDay(daily)!.value, 5000);
      expect(weeklyTotals(daily), {
        DateTime(2026, 10, 12): 4000,
        DateTime(2026, 10, 19): 5000,
      });
    });

    test('weekly averages use only days with data', () {
      expect(
        weeklyAverages(daily, DateTime(2026, 10, 12), DateTime(2026, 10, 20)),
        [2000, 5000],
      );
    });

    test('usual steps by now', () {
      final hours = [for (var h = 0; h < 24; h++) h >= 8 && h < 20 ? 100 : 0];
      expect(usualStepsBy([hours], DateTime(2026, 10, 20, 14, 30)), 650);
      expect(usualStepsBy([], DateTime(2026, 10, 20, 14)), isNull);
    });
  });

  group('sleep summaries', () {
    SleepSession night(int day, int bedHour, int bedMin, Duration asleep) {
      final start = DateTime(2026, 10, day, bedHour, bedMin);
      return SleepSession(start: start, end: start.add(asleep), asleep: asleep);
    }

    test('debt only counts short nights', () {
      final nights = [
        night(18, 23, 0, const Duration(hours: 7)),
        night(19, 23, 0, const Duration(hours: 9)),
      ];
      expect(
        sleepDebt(nights, const Duration(hours: 7, minutes: 30)),
        const Duration(minutes: 30),
      );
    });

    test('bedtime spread works across midnight', () {
      final nights = [
        night(18, 23, 30, const Duration(hours: 7)),
        night(19, 0, 30, const Duration(hours: 7)),
      ];
      expect(bedtimeSpread(nights), const Duration(minutes: 30));
      expect(bedtimeSpread(nights.take(1)), isNull);
    });

    test('stage totals', () {
      final t = DateTime(2026, 10, 20);
      final totals = stageTotals([
        SleepSegment(SleepStage.deep, t, t.add(const Duration(minutes: 40))),
        SleepSegment(SleepStage.light, t, t.add(const Duration(minutes: 10))),
        SleepSegment(SleepStage.deep, t, t.add(const Duration(minutes: 5))),
      ]);
      expect(totals[SleepStage.deep], const Duration(minutes: 45));
      expect(totals[SleepStage.rem], Duration.zero);
    });
  });
}
