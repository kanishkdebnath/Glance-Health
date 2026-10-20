import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_health/app/providers.dart';
import 'package:glance_health/core/goals.dart';
import 'package:glance_health/core/health/health_data_source.dart';
import 'package:glance_health/core/health/mock_health_data_source.dart';
import 'package:glance_health/core/pace.dart';
import 'package:glance_health/features/home/home_summary.dart';
import 'package:glance_health/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tuesday 20 October 2026, 3:08 pm: the moment shown in the design document.
DateTime fixedNow() => DateTime(2026, 10, 20, 15, 8);

void main() {
  test('home summary from the mock matches the design', () async {
    final s = await loadHomeSummary(
      MockHealthDataSource(clock: fixedNow),
      const Goals(),
      fixedNow(),
    );
    expect(
      s.steps,
      inInclusiveRange(5000, 6500),
    ); // morning-to-3pm share of a 9,380-step profile
    expect(s.progress, StepProgress.onPace);
    expect(s.sleep.today.valueOrNull, const Duration(hours: 7, minutes: 18));
    expect(s.restingHr.today.valueOrNull, 58);
    expect(s.sleep.week, hasLength(7));
  });

  test('a metric the device lacks reads as unsupported', () async {
    final src = MockHealthDataSource(
      clock: fixedNow,
      supported: Metric.values.toSet()..remove(Metric.spo2),
    );
    final s = await loadHomeSummary(src, const Goals(), fixedNow());
    expect(s.spo2, isA<Unsupported<double>>());
  });

  test('home summary survives a save and load', () async {
    final s = await loadHomeSummary(
      MockHealthDataSource(clock: fixedNow),
      const Goals(),
      fixedNow(),
    );
    final back = HomeSummary.fromJson(
      jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
    );
    expect(back.steps, s.steps);
    expect(back.headline, s.headline);
    expect(back.sleep.today.valueOrNull, s.sleep.today.valueOrNull);
    expect(back.restingHr.usual?.low, s.restingHr.usual?.low);
    expect(back.spo2.valueOrNull, s.spo2.valueOrNull);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('home renders in ${mode.name} mode', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      // The background drifts forever; reduce-motion keeps the test settling.
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fixedNow),
          prefsProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).set(mode);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const GlanceApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TUESDAY, 20 OCTOBER'), findsOneWidget);
      expect(find.textContaining("on pace for your step goal"), findsOneWidget);
      expect(find.text('Sleep'), findsWidgets);
      expect(find.text('Resting HR'), findsOneWidget);
      expect(find.text('On pace'), findsOneWidget);
      expect(find.text('Showing sample data'), findsOneWidget);
    });
  }
}
