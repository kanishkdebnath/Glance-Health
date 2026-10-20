import 'package:flutter/material.dart';

import '../design/metric_family.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

// ponytail: stand-in for tabs that are designed but not built yet.
// Delete once Steps, Sleep and Heart have their real screens.
class PlannedScreen extends StatelessWidget {
  const PlannedScreen({super.key, required this.title, required this.family});
  final String title;
  final MetricFamily family;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Wash(
      colors: p.family(family),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Space.screen),
          children: [
            Text(title, style: t.title),
            const SizedBox(height: Space.xl),
            GlassCard(
              child: Text(
                'This screen is next in the build. See the design document for its layout.',
                style: t.bodyMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
