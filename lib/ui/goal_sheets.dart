import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/format.dart';
import '../core/goals.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

/// Edit the daily step goal (and an optional weekend goal).
Future<void> showStepGoalSheet(BuildContext context) =>
    showGlassSheet(context, builder: (_) => const _StepGoalSheet());

/// Edit the nightly sleep target.
Future<void> showSleepTargetSheet(BuildContext context) =>
    showGlassSheet(context, builder: (_) => const _SleepTargetSheet());

class _StepGoalSheet extends ConsumerStatefulWidget {
  const _StepGoalSheet();

  @override
  ConsumerState<_StepGoalSheet> createState() => _StepGoalSheetState();
}

class _StepGoalSheetState extends ConsumerState<_StepGoalSheet> {
  late final Goals _start = ref.read(goalsProvider);
  late int _steps = _start.steps;
  late int? _weekend = _start.weekendSteps;

  static int _clamp(int v) => v.clamp(Goals.stepsMin, Goals.stepsMax);

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.palette;
    return _SheetBody(
      title: 'Daily step goal',
      children: [
        _Stepper(
          value: MetricText([(thousands(_steps), '')], style: t.hero),
          semantics: '${thousands(_steps)} steps',
          onMinus: () =>
              setState(() => _steps = _clamp(_steps - Goals.stepsStep)),
          onPlus: () =>
              setState(() => _steps = _clamp(_steps + Goals.stepsStep)),
        ),
        _Presets(
          values: const [6000, 7000, 8000, 10000, 12000],
          selected: _steps,
          label: thousands,
          onSelected: (v) => setState(() => _steps = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Different goal on weekends', style: t.body),
          value: _weekend != null,
          activeTrackColor: p.steps.main,
          onChanged: (on) =>
              setState(() => _weekend = on ? _clamp(_steps - 2000) : null),
        ),
        if (_weekend case final w?)
          _Stepper(
            compact: true,
            label: 'Sat & Sun',
            value: MetricText([(thousands(w), '')], style: t.metricSmall),
            semantics: '${thousands(w)} steps on weekends',
            onMinus: () =>
                setState(() => _weekend = _clamp(w - Goals.stepsStep)),
            onPlus: () =>
                setState(() => _weekend = _clamp(w + Goals.stepsStep)),
          ),
        Text('Applies from today.', style: t.small),
        FilledButton(
          onPressed: () {
            ref
                .read(goalsProvider.notifier)
                .set(
                  Goals(
                    steps: _steps,
                    weekendSteps: _weekend,
                    sleep: _start.sleep,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Save goal'),
        ),
      ],
    );
  }
}

class _SleepTargetSheet extends ConsumerStatefulWidget {
  const _SleepTargetSheet();

  @override
  ConsumerState<_SleepTargetSheet> createState() => _SleepTargetSheetState();
}

class _SleepTargetSheetState extends ConsumerState<_SleepTargetSheet> {
  late final Goals _start = ref.read(goalsProvider);
  late Duration _sleep = _start.sleep;

  void _add(Duration d) {
    final v = _sleep + d;
    if (v >= Goals.sleepMin && v <= Goals.sleepMax) setState(() => _sleep = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return _SheetBody(
      title: 'Sleep target',
      children: [
        _Stepper(
          value: MetricText(hoursMinutesParts(_sleep), style: t.hero),
          semantics: hoursMinutes(_sleep),
          onMinus: () => _add(-Goals.sleepStep),
          onPlus: () => _add(Goals.sleepStep),
        ),
        _Presets(
          values: const [420, 450, 480, 510],
          selected: _sleep.inMinutes,
          label: (m) => hoursMinutes(Duration(minutes: m)),
          onSelected: (m) => setState(() => _sleep = Duration(minutes: m)),
        ),
        Text(
          'Used for sleep debt and the week dots on the Sleep tab.',
          style: t.small,
        ),
        FilledButton(
          onPressed: () {
            ref
                .read(goalsProvider.notifier)
                .set(
                  Goals(
                    steps: _start.steps,
                    weekendSteps: _start.weekendSteps,
                    sleep: _sleep,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Save target'),
        ),
      ],
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
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
          Text(title, style: context.type.headline),
          ...children,
        ],
      ),
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.semantics,
    required this.onMinus,
    required this.onPlus,
    this.compact = false,
    this.label,
  });
  final Widget value;
  final String semantics;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool compact;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GlassSurface(
      radius: Radii.button + 2,
      shadow: false,
      fill: p.chip.withValues(alpha: 0.45),
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 10),
        child: Row(
          children: [
            CircleIconButton(
              icon: Icons.remove_rounded,
              tooltip: 'Less',
              onPressed: onMinus,
            ),
            Expanded(
              child: Column(
                children: [
                  if (label != null) Text(label!, style: context.type.small),
                  Semantics(liveRegion: true, label: semantics, child: value),
                ],
              ),
            ),
            CircleIconButton(
              icon: Icons.add_rounded,
              tooltip: 'More',
              onPressed: onPlus,
            ),
          ],
        ),
      ),
    );
  }
}

class _Presets extends StatelessWidget {
  const _Presets({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });
  final List<int> values;
  final int selected;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(v),
            labelStyle: t.chip.copyWith(
              color: v == selected ? p.background : p.ink2,
            ),
            selectedColor: p.ink,
            backgroundColor: Colors.transparent,
            side: BorderSide(color: v == selected ? p.ink : p.line),
            shape: const StadiumBorder(),
          ),
      ],
    );
  }
}
