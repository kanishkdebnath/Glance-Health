import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/health/data_check.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';

final dataCheckProvider = FutureProvider.autoDispose<DataCheckReport>(
  (ref) => runDataCheck(),
);

/// What Health Connect actually holds: record counts, source apps,
/// granularity and history depth. Fills in the spike's findings table.
class DataCheckScreen extends ConsumerWidget {
  const DataCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.type;
    final p = context.palette;
    final report = ref.watch(dataCheckProvider);
    return Wash(
      colors: Wash.mix(p.steps, p.heart),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          title: const Text('Data check'),
          backgroundColor: Colors.transparent,
          actions: [
            if (report case AsyncData(:final value))
              IconButton(
                tooltip: 'Copy report',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value.toText()));
                  if (context.mounted) {
                    showGlassToast(context, 'Report copied');
                  }
                },
              ),
          ],
        ),
        body: switch (report) {
          AsyncData(:final value) => ListView(
            padding: const EdgeInsets.all(Space.screen),
            children: [
              Text(
                'Last 30 days from Health Connect (24 hours for steps and heart rate), read on this phone.',
                style: t.bodyMuted,
              ),
              const SizedBox(height: Space.l),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.xs,
                  children: [
                    Text('Steps today', style: t.label),
                    Text(
                      'Health Connect total: ${value.stepsTodayAggregate == null ? '—' : thousands(value.stepsTodayAggregate!)}',
                      style: t.body,
                    ),
                    for (final e in value.stepsTodayBySource.entries)
                      Text('${e.key}: ${thousands(e.value)}', style: t.small),
                    if (value.stepsTodayBySource.length > 1)
                      Text(
                        'More than one app writes steps. Health Connect counts them once, in its priority order.',
                        style: t.small.copyWith(color: p.warning),
                      ),
                    Text(
                      'Steps history goes back to: ${value.oldestSteps == null ? '—' : longDate(value.oldestSteps!)}',
                      style: t.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
              for (final f in value.findings) ...[
                _FindingCard(f),
                const SizedBox(height: Space.s),
              ],
            ],
          ),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.all(Space.screen),
            child: Text("Couldn't read Health Connect: $error", style: t.body),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard(this.f);
  final TypeFinding f;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.palette;
    final empty = f.count == 0;
    String d(DateTime? x) =>
        x == null ? '—' : '${x.day}/${x.month} ${clockTime(x)}';
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Space.xxs,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(f.type.name, style: t.label.copyWith(color: p.ink)),
              ),
              Pill(
                label: empty
                    ? 'None'
                    : '${thousands(f.count)} in ${f.window.inDays == 1 ? '24h' : '${f.window.inDays}d'}',
                tone: empty ? PillTone.dashed : PillTone.neutral,
              ),
            ],
          ),
          if (!empty) ...[
            Text(
              'From: ${f.sources.entries.map((e) => '${e.key} (${e.value})').join(', ')}',
              style: t.small,
            ),
            Text(
              '${d(f.first)} → ${d(f.last)} · typical record ${f.typicalSpan?.inMinutes ?? '—'} min',
              style: t.small,
            ),
            Text(
              'Last: ${f.lastValue}',
              style: t.small,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
