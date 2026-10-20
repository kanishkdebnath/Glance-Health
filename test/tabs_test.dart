import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance_health/app/providers.dart';
import 'package:glance_health/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

DateTime fixedNow() => DateTime(2026, 10, 20, 15, 8);

Future<void> pumpApp(WidgetTester tester, ThemeMode mode) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
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
    UncontrolledProviderScope(container: container, child: const GlanceApp()),
  );
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('steps tab, every range (${mode.name})', (tester) async {
      await pumpApp(tester, mode);
      await openTab(tester, 'Steps');
      expect(find.text('By hour'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      for (final r in ['7D', '30D', '90D', 'Year']) {
        await tester.tap(find.text(r));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: r);
      }
      expect(find.text('Best month'), findsOneWidget);
    });

    testWidgets('sleep tab (${mode.name})', (tester) async {
      await pumpApp(tester, mode);
      await openTab(tester, 'Sleep');
      expect(find.text('LAST NIGHT'), findsOneWidget);
      expect(find.text('Sleep stages'), findsOneWidget);
      expect(find.text('Last 7 nights'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Schedule'), 200);
      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('heart tab, every range (${mode.name})', (tester) async {
      await pumpApp(tester, mode);
      await openTab(tester, 'Heart');
      expect(find.text('RESTING'), findsOneWidget);
      expect(find.text('Day range'), findsOneWidget);
      for (final r in ['7D', '90D', 'Year']) {
        await tester.tap(find.text(r));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: r);
      }
      await tester.scrollUntilVisible(find.text('SpO2'), 200);
      expect(find.text('HRV'), findsOneWidget);
    });
  }

  testWidgets('step goal sheet saves a new goal', (tester) async {
    await pumpApp(tester, ThemeMode.light);
    await openTab(tester, 'Steps');
    await tester.tap(find.byTooltip('Edit step goal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10,000'));
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of 10,000'), findsOneWidget);
  });
}
