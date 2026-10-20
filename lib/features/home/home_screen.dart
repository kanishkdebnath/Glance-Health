import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/tabs.dart';
import '../../core/format.dart';
import '../../core/health/health_data_source.dart';
import '../../core/pace.dart';
import '../../design/charts/step_gauge.dart';
import '../../design/metric_family.dart';
import '../../design/motion.dart';
import '../../design/theme.dart';
import '../../design/tokens.dart';
import '../../design/widgets.dart';
import '../../ui/detail_page.dart';
import '../../ui/metric_card.dart';
import 'home_summary.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final fresh = ref.watch(homeSummaryProvider);
    // Show the last saved values at once; fresh data replaces them when ready.
    final data = fresh.value ?? ref.watch(cachedHomeSummaryProvider);
    final sample = ref.watch(dataModeProvider) == DataMode.sample;
    return Wash(
      colors: Wash.mix(p.steps, p.sleep),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeSummaryProvider.future),
          child: AnimatedSwitcher(
            duration: motion(context, const Duration(milliseconds: 350)),
            child: switch (data) {
              final s? => _HomeBody(
                s,
                sample: sample,
                refreshing: fresh.isLoading,
                failed: fresh.hasError && !fresh.isLoading,
                onRetry: () => ref.invalidate(homeSummaryProvider),
              ),
              null when fresh.hasError => _HomeError(
                onRetry: () => ref.invalidate(homeSummaryProvider),
              ),
              null => const _HomeSkeleton(),
            },
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody(
    this.s, {
    required this.sample,
    required this.refreshing,
    required this.failed,
    required this.onRetry,
  });
  final HomeSummary s;
  final bool sample;
  final bool refreshing;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    void openTab(AppTab tab) =>
        StatefulNavigationShell.maybeOf(context)?.goBranch(tab.index);

    return ListView(
      padding: screenPadding(context),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(longDate(s.date).toUpperCase(), style: t.eyebrow),
                  const SizedBox(height: Space.xxs),
                  _SyncStatus(
                    s,
                    refreshing: refreshing,
                    failed: failed,
                    onRetry: onRetry,
                  ),
                ],
              ),
            ),
            CircleIconButton(
              icon: Icons.settings_rounded,
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        if (sample) ...[
          const SizedBox(height: Space.m),
          GlassCard(
            radius: Radii.button,
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            onTap: () => context.push('/settings'),
            child: Row(
              children: [
                Icon(Icons.science_rounded, size: 18, color: p.ink2),
                const SizedBox(width: Space.s),
                Expanded(child: Text('Showing sample data', style: t.small)),
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.l),
        Entrance(
          index: 0,
          // Cross-fades when a refresh changes the sentence.
          child: AnimatedSwitcher(
            duration: motion(context, const Duration(milliseconds: 400)),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, ?current],
            ),
            child: Text(
              s.headline,
              key: ValueKey(s.headline),
              style: t.headline,
            ),
          ),
        ),
        const SizedBox(height: Space.l),
        // The pace row sits inside the arc's open bottom.
        Entrance(
          index: 1,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Center(child: _StepsGauge(s)),
              Positioned(
                bottom: Space.s,
                left: 0,
                right: 0,
                child: _PaceRow(s),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xl),
        Entrance(
          index: 2,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Space.m,
              children: [
                Expanded(
                  child: MetricCard<Duration>(
                    family: MetricFamily.sleep,
                    label: 'Sleep',
                    reading: s.sleep.today,
                    valueParts: hoursMinutesParts,
                    status: s.sleep.status,
                    week: s.sleep.week,
                    semanticsUnit: 'asleep',
                    onTap: () => openTab(AppTab.sleep),
                  ),
                ),
                Expanded(
                  child: MetricCard<int>(
                    family: MetricFamily.heart,
                    label: 'Resting HR',
                    reading: s.restingHr.today,
                    valueParts: (v) => [('$v', ' bpm')],
                    status: s.restingHr.status,
                    week: s.restingHr.week,
                    band: s.restingHr.usual == null
                        ? null
                        : (s.restingHr.usual!.low, s.restingHr.usual!.high),
                    semanticsUnit: '',
                    onTap: () => openTab(AppTab.heart),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.m),
        Entrance(index: 3, child: _CompactRow(s)),
      ],
    );
  }
}

class _StepsGauge extends StatelessWidget {
  const _StepsGauge(this.s);
  final HomeSummary s;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final met = s.progress == StepProgress.goalMet;
    final size = (MediaQuery.sizeOf(context).width - Space.screen * 2).clamp(
      200.0,
      280.0,
    );
    return StepGauge(
      value: s.steps,
      goal: s.stepGoal,
      pace: met ? null : s.usualFraction,
      colors: p.steps,
      size: size,
      semanticsLabel: '${thousands(s.steps)} of ${thousands(s.stepGoal)} steps',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_rounded : MetricFamily.steps.icon,
            color: p.steps.main,
            size: 22,
          ),
          AnimatedCount(s.steps, style: t.hero),
          const SizedBox(height: Space.xs),
          Text(
            met
                ? '+${thousands(s.steps - s.stepGoal)} over goal'
                : 'of ${thousands(s.stepGoal)} steps',
            style: t.small,
          ),
        ],
      ),
    );
  }
}

class _PaceRow extends StatelessWidget {
  const _PaceRow(this.s);
  final HomeSummary s;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final toGo = '${thousands(s.stepGoal - s.steps)} to go';
    final (Widget? pill, String text) = switch (s.progress) {
      StepProgress.goalMet => (
        Pill(
          label: 'Goal reached',
          icon: Icons.check_rounded,
          iconColor: p.steps.main,
          tone: PillTone.tinted,
          tint: p.steps.track,
        ),
        '',
      ),
      StepProgress.onPace => (
        Pill(
          label: 'On pace',
          icon: Icons.check_rounded,
          iconColor: p.steps.main,
          tone: PillTone.tinted,
          tint: p.steps.track,
        ),
        toGo,
      ),
      StepProgress.behind => (const Pill(label: 'Behind usual pace'), toGo),
      StepProgress.noData => (null, 'No steps synced yet today'),
    };
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Space.s,
      runSpacing: Space.xs,
      children: [
        ?pill,
        if (text.isNotEmpty) Text(text, style: t.small),
      ],
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow(this.s);
  final HomeSummary s;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cells = [
      (
        Icons.bolt_rounded,
        p.steps.main,
        'Active',
        s.activeMinutes.valueOrNull?.toString(),
        ' min',
        s.activeMinutes,
      ),
      (
        Icons.monitor_heart_rounded,
        p.heart.main,
        'HRV',
        s.hrv.valueOrNull?.round().toString(),
        ' ms',
        s.hrv,
      ),
      (
        Icons.water_drop_rounded,
        p.heart.main,
        'SpO2',
        s.spo2.valueOrNull?.round().toString(),
        '%',
        s.spo2,
      ),
    ];
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: Space.xs),
      radius: Radii.list,
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, c) in cells.indexed) ...[
              if (i > 0) VerticalDivider(color: p.line, width: 1),
              Expanded(
                child: _CompactCell(
                  icon: c.$1,
                  color: c.$2,
                  label: c.$3,
                  value: c.$4,
                  unit: c.$5,
                  reading: c.$6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactCell extends StatelessWidget {
  const _CompactCell({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.reading,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String? value;
  final String unit;
  final Reading<Object> reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xs),
      child: Column(
        spacing: Space.xxs,
        children: [
          Icon(icon, size: 16, color: color),
          if (value != null)
            MetricText([(value!, unit)], style: t.metricSmall)
          else
            Text('—', style: t.metricSmall.copyWith(color: p.ink3)),
          Text(
            switch (reading) {
              Unsupported() => 'Not available from your device',
              NoData() => 'No data yet',
              Value() => label,
            },
            style: t.small.copyWith(fontSize: reading is Value ? 12 : 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// "Synced 3:08 pm", a spinning "Updating…" during a refresh, or a retry
/// link when the refresh failed and saved values are showing.
class _SyncStatus extends StatelessWidget {
  const _SyncStatus(
    this.s, {
    required this.refreshing,
    required this.failed,
    required this.onRetry,
  });
  final HomeSummary s;
  final bool refreshing;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final today = DateUtils.isSameDay(s.date, DateTime.now());
    final synced = s.syncedAt == null
        ? 'Not synced yet'
        : 'Synced ${today ? '' : '${longDate(s.syncedAt!).split(',').first}, '}${clockTime(s.syncedAt!)}';
    final (text, color) = refreshing
        ? ('Updating…', p.ink2)
        : failed
        ? ("Couldn't update · Try again", p.warning)
        : (synced, p.ink3);
    return GestureDetector(
      onTap: failed ? onRetry : null,
      child: Row(
        children: [
          SpinningIcon(
            Icons.sync_rounded,
            spinning: refreshing,
            size: 14,
            color: color,
          ),
          const SizedBox(width: Space.xs),
          AnimatedSwitcher(
            duration: motion(context, const Duration(milliseconds: 250)),
            child: Text(
              text,
              key: ValueKey(text),
              style: t.small.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// First launch only: the Home layout in shimmering placeholders.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width - Space.screen * 2).clamp(
      200.0,
      280.0,
    );
    return Shimmer(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: screenPadding(context),
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Space.s,
                  children: [
                    Bone(width: 150, height: 12),
                    Bone(width: 100, height: 10),
                  ],
                ),
              ),
              Bone(width: 44, height: 44, radius: 22),
            ],
          ),
          const SizedBox(height: Space.xl),
          const Bone(height: 18),
          const SizedBox(height: Space.s),
          const Bone(height: 18),
          const SizedBox(height: Space.s),
          const FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.6,
            child: Bone(height: 18),
          ),
          const SizedBox(height: Space.xl),
          Center(
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _ArcBone(
                  context.palette.isDark
                      ? context.palette.chip
                      : context.palette.line,
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          const Row(
            spacing: Space.m,
            children: [
              Expanded(child: Bone(height: 150, radius: Radii.card)),
              Expanded(child: Bone(height: 150, radius: Radii.card)),
            ],
          ),
          const SizedBox(height: Space.m),
          const Bone(height: 84, radius: Radii.list),
        ],
      ),
    );
  }
}

class _ArcBone extends CustomPainter {
  _ArcBone(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.width * 0.075;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - sw / 2 - 14,
    );
    canvas.drawArc(
      rect,
      0.75 * 3.14159,
      1.5 * 3.14159,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round,
    );
    final c = size.center(Offset.zero);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: size.width * 0.45, height: 44),
        const Radius.circular(10),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_ArcBone old) => old.color != color;
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return ListView(
      padding: const EdgeInsets.all(Space.screen),
      children: [
        const SizedBox(height: 120),
        Text(
          "Couldn't read your health data",
          style: t.headline,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.s),
        Text(
          'Check that Glance Health still has access, then try again.',
          style: t.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Space.l),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
