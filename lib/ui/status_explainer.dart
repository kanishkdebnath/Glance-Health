import 'package:flutter/material.dart';

import '../core/baseline.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import 'status_pill.dart';

/// "How usual works": opened from the info button on the Heart tab.
Future<void> showStatusExplainer(BuildContext context) => showModalBottomSheet(
  context: context,
  builder: (context) {
    final t = context.type;
    final p = context.palette;
    const rows = [
      (BaselineStatus.below, 'Lower than most of your recent days'),
      (BaselineStatus.typical, 'Within your usual range'),
      (BaselineStatus.above, 'Higher than most of your recent days'),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.screen,
          0,
          Space.screen,
          Space.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Space.m,
          children: [
            Text('How "usual" works', style: t.headline),
            Text(
              'Each number is compared with your own last 30 days, not with '
              'other people. Labels appear once there are 14 days of data.',
              style: t.small,
            ),
            for (final (status, text) in rows)
              Row(
                spacing: Space.m,
                children: [
                  SizedBox(
                    width: 124,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(status),
                    ),
                  ),
                  Expanded(child: Text(text, style: t.small)),
                ],
              ),
            Text(
              "These labels describe change. They don't mean good or bad, "
              "and they aren't medical advice.",
              style: t.small.copyWith(color: p.ink3),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: p.chip,
                foregroundColor: p.ink,
              ),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  },
);
