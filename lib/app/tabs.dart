import 'package:flutter/material.dart';

import '../design/metric_family.dart';
import '../features/heart/heart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/sleep/sleep_screen.dart';
import '../features/steps/steps_screen.dart';

/// The bottom tabs, in order. The router and tab bar are both built from
/// this list, so a new tab (e.g. Training) is one entry here.
enum AppTab {
  today('Today', '/', Icons.donut_large_rounded, HomeScreen.new),
  steps('Steps', '/steps', Icons.directions_walk_rounded, StepsScreen.new),
  sleep('Sleep', '/sleep', Icons.bedtime_rounded, SleepScreen.new),
  heart('Heart', '/heart', Icons.favorite_rounded, HeartScreen.new);

  const AppTab(this.label, this.path, this.icon, this.screen);
  final String label;
  final String path;
  final IconData icon;
  final Widget Function({Key? key}) screen;

  /// Icon tint when selected; Today stays neutral.
  MetricFamily? get family => switch (this) {
    today => null,
    steps => MetricFamily.steps,
    sleep => MetricFamily.sleep,
    heart => MetricFamily.heart,
  };
}
