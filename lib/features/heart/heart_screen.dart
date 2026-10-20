import 'package:flutter/material.dart';

import '../../design/metric_family.dart';
import '../../ui/planned_screen.dart';

class HeartScreen extends StatelessWidget {
  const HeartScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlannedScreen(title: 'Heart', family: MetricFamily.heart);
}
