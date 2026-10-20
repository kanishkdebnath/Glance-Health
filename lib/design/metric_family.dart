import 'package:flutter/material.dart';

import 'palette.dart';

/// Each family owns one hue. Secondary metrics borrow their family's hue:
/// active minutes belong to steps; HRV and SpO2 belong to heart.
///
/// Adding a family (for example training, for workout and strength logs)
/// means adding a value here and a [MetricColors] entry in [GlancePalette].
/// The exhaustive switches below then point at every place that needs it.
enum MetricFamily {
  steps(Icons.directions_walk_rounded),
  sleep(Icons.bedtime_rounded),
  heart(Icons.favorite_rounded),
  cycle(Icons.radio_button_checked_rounded);

  const MetricFamily(this.icon);
  final IconData icon;
}

extension PaletteFamilies on GlancePalette {
  MetricColors family(MetricFamily f) => switch (f) {
    MetricFamily.steps => steps,
    MetricFamily.sleep => sleep,
    MetricFamily.heart => heart,
    MetricFamily.cycle => cycle,
  };
}
