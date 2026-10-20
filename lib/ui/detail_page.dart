import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/metric_family.dart';
import '../design/motion.dart';
import '../design/theme.dart';
import '../design/tokens.dart';
import '../design/widgets.dart';

/// The frame shared by the Steps and Heart tabs: the family's wash, pull to
/// refresh, a skeleton on first load and a retry on failure. Children
/// enter one after another.
class DetailPage<T> extends ConsumerWidget {
  const DetailPage({
    super.key,
    required this.family,
    required this.provider,
    required this.header,
    required this.builder,
  });

  final MetricFamily family;
  final FutureProvider<T> provider;
  final Widget header;
  final List<Widget> Function(BuildContext context, T data) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(provider);
    return Wash(
      colors: context.palette.family(family),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: switch (data) {
            AsyncValue(:final value?) => ListView(
              padding: screenPadding(context),
              children: [
                header,
                const SizedBox(height: Space.l),
                for (final (i, w) in builder(context, value).indexed)
                  Entrance(index: i, child: w),
              ],
            ),
            AsyncValue(hasError: true) => LoadError(
              onRetry: () => ref.invalidate(provider),
            ),
            _ => const DetailSkeleton(),
          },
        ),
      ),
    );
  }
}

/// Screen padding that leaves room under the floating tab bar.
EdgeInsets screenPadding(BuildContext context) => EdgeInsets.fromLTRB(
  Space.screen,
  Space.s,
  Space.screen,
  Space.xl + MediaQuery.paddingOf(context).bottom,
);

/// Space between stacked cards on detail screens.
const detailGap = SizedBox(height: Space.m);

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: screenPadding(context),
      children: const [
        Bone(width: 120, height: 30),
        SizedBox(height: Space.l),
        Bone(height: 36, radius: Radii.button),
        SizedBox(height: Space.l),
        Bone(width: 160, height: 48),
        SizedBox(height: Space.l),
        Bone(height: 180, radius: Radii.card),
        SizedBox(height: Space.m),
        Bone(height: 120, radius: Radii.card),
      ],
    ),
  );
}

class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.onRetry});
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

/// Screen title with one round action on the right.
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });
  final String title;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: context.type.title)),
      CircleIconButton(icon: icon, tooltip: tooltip, onPressed: onPressed),
    ],
  );
}

/// Small caps label above a group of rows.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xs, Space.s, 0, Space.xs),
    child: Text(
      text.toUpperCase(),
      style: context.type.eyebrow.copyWith(color: context.palette.ink3),
    ),
  );
}

/// A card holding rows separated by hairlines.
class RowList extends StatelessWidget {
  const RowList({super.key, required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: EdgeInsets.zero,
    radius: Radii.list,
    child: Column(
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const Divider(indent: Space.card, endIndent: Space.card),
          r,
        ],
      ],
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.detail,
  });
  final IconData? icon;
  final Color? iconColor;
  final String label;
  final String? detail;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.card, vertical: 12),
      child: Row(
        spacing: Space.m,
        children: [
          if (icon != null) Icon(icon, size: 18, color: iconColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.body),
                if (detail != null) Text(detail!, style: t.small),
              ],
            ),
          ),
          Text(value, style: t.body.copyWith(color: context.palette.ink2)),
        ],
      ),
    );
  }
}

/// Colour swatch and name, for chart legends.
class LegendItem extends StatelessWidget {
  const LegendItem(this.color, this.label, {super.key, this.value});
  final Color color;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: t.chart),
        if (value != null) ...[
          const SizedBox(width: 4),
          Text(
            value!,
            style: t.chart.copyWith(
              color: context.palette.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
