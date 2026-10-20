import 'package:flutter_test/flutter_test.dart';
import 'package:glance_health/core/baseline.dart';
import 'package:glance_health/core/format.dart';
import 'package:glance_health/core/goals.dart';
import 'package:glance_health/core/pace.dart';
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
}
