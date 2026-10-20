import 'package:flutter/material.dart';

import '../../design/metric_family.dart';
import '../../ui/planned_screen.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlannedScreen(title: 'Sleep', family: MetricFamily.sleep);
}
