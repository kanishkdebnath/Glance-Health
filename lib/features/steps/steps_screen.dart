import 'package:flutter/material.dart';

import '../../design/metric_family.dart';
import '../../ui/planned_screen.dart';

class StepsScreen extends StatelessWidget {
  const StepsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlannedScreen(title: 'Steps', family: MetricFamily.steps);
}
