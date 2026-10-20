import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/goals.dart';
import '../core/health/cached_source.dart';
import '../core/health/health_connect_source.dart';
import '../core/health/health_data_source.dart';
import '../core/health/mock_health_data_source.dart';
import '../design/theme.dart';

/// Loaded in main() before the app starts; overridden there and in tests.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('prefsProvider must be overridden'),
);

/// Override in tests to freeze time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

enum DataMode { sample, healthConnect }

class DataModeController extends Notifier<DataMode> {
  static const _key = 'dataMode';

  @override
  DataMode build() =>
      DataMode.values.asNameMap()[ref.watch(prefsProvider).getString(_key)] ??
      DataMode.sample;

  void set(DataMode mode) {
    ref.read(prefsProvider).setString(_key, mode.name);
    state = mode;
  }
}

final dataModeProvider = NotifierProvider<DataModeController, DataMode>(
  DataModeController.new,
);

final healthAccessProvider = Provider<HealthConnectAccess>(
  (ref) => HealthConnectAccess(),
);

final healthStatusProvider = FutureProvider<HealthConnectStatus>(
  (ref) => ref.watch(healthAccessProvider).status(),
);

/// Sample data until the user connects Health Connect.
final healthSourceProvider = Provider<HealthDataSource>((ref) {
  final clock = ref.watch(clockProvider);
  return switch (ref.watch(dataModeProvider)) {
    DataMode.sample => MockHealthDataSource(clock: clock),
    DataMode.healthConnect => CachedHourlySource(
      HealthConnectSource(clock: clock),
      read: ref.read(prefsProvider).getString,
      write: (k, v) => ref.read(prefsProvider).setString(k, v),
      clock: clock,
    ),
  };
});

/// Current goals, saved on this phone.
// ponytail: one current value per goal. Goal history ("changes apply from
// that day forward") moves into drift; until then past days are measured
// against today's goal.
class GoalsController extends Notifier<Goals> {
  static const _steps = 'goals.steps';
  static const _weekend = 'goals.weekendSteps';
  static const _sleep = 'goals.sleepMinutes';

  @override
  Goals build() {
    final prefs = ref.watch(prefsProvider);
    const d = Goals();
    return Goals(
      steps: prefs.getInt(_steps) ?? d.steps,
      weekendSteps: prefs.getInt(_weekend),
      sleep: Duration(minutes: prefs.getInt(_sleep) ?? d.sleep.inMinutes),
    );
  }

  void set(Goals g) {
    final prefs = ref.read(prefsProvider);
    prefs.setInt(_steps, g.steps);
    final weekend = g.weekendSteps;
    weekend == null ? prefs.remove(_weekend) : prefs.setInt(_weekend, weekend);
    prefs.setInt(_sleep, g.sleep.inMinutes);
    state = g;
  }
}

final goalsProvider = NotifierProvider<GoalsController, Goals>(
  GoalsController.new,
);

/// Which light/dark palette pair the app uses.
final themeSetProvider = Provider<GlanceThemeSet>(
  (ref) => GlanceThemeSet.standard,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() =>
      ThemeMode.values.asNameMap()[ref.watch(prefsProvider).getString(_key)] ??
      ThemeMode.system;

  void set(ThemeMode mode) {
    ref.read(prefsProvider).setString(_key, mode.name);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
