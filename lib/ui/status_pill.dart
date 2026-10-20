import 'package:flutter/material.dart';

import '../core/baseline.dart';
import '../design/widgets.dart';

/// Below usual / Typical / Above usual. Neutral fill on purpose: the app
/// describes change and never calls a value good or bad.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final BaselineStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    BaselineStatus.below => const Pill(
      label: 'Below usual',
      icon: Icons.south_rounded,
    ),
    BaselineStatus.typical => const Pill(
      label: 'Typical',
      icon: Icons.drag_handle_rounded,
    ),
    BaselineStatus.above => const Pill(
      label: 'Above usual',
      icon: Icons.north_rounded,
    ),
    BaselineStatus.learning => const Pill(
      label: 'Learning your usual',
      tone: PillTone.outline,
    ),
  };
}

class UnavailablePill extends StatelessWidget {
  const UnavailablePill({super.key});

  @override
  Widget build(BuildContext context) =>
      const Pill(label: 'Not available', tone: PillTone.dashed);
}
