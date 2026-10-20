import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'palette.dart';
import 'theme.dart';
import 'tokens.dart';

/// Screen background: the palette background with two soft colour blooms
/// at the top, taken from a metric family.
class Wash extends StatefulWidget {
  const Wash({super.key, required this.colors, required this.child});

  /// Usually a family's colours. Home mixes steps and sleep: pass
  /// `Wash.mix(p.steps, p.sleep)`.
  final MetricColors colors;
  final Widget child;

  static MetricColors mix(MetricColors a, MetricColors b) => MetricColors(
    main: a.main,
    second: b.main,
    dim: a.dim,
    track: a.track,
    wash: a.wash,
    wash2: b.wash,
  );

  @override
  State<Wash> createState() => _WashState();
}

class _WashState extends State<Wash> with SingleTickerProviderStateMixin {
  // One slow loop. The blooms drift on different paths so the motion never
  // looks mechanical. Flutter stops ticking when the app is in the background.
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _drift.isAnimating) _drift.stop();
    if (!still && !_drift.isAnimating) _drift.repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.background,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WashPainter(
                    _drift,
                    widget.colors.wash,
                    widget.colors.wash2,
                  ),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _WashPainter extends CustomPainter {
  _WashPainter(this.t, this.a, this.b) : super(repaint: t);
  final Animation<double> t;
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t.value * 2 * math.pi;
    final w = size.width;
    void bloom(Offset centre, double radius, Color c) {
      final rect = Rect.fromCircle(center: centre, radius: radius);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            colors: [c, c.withValues(alpha: 0)],
          ).createShader(rect),
      );
    }

    // Drift about 8% of the width; radius breathes by about 6%.
    bloom(
      Offset(
        w * (-0.05 + 0.08 * math.sin(phase)),
        w * (-0.05 + 0.06 * math.cos(phase)),
      ),
      w * (1.05 + 0.06 * math.sin(phase * 2)),
      a,
    );
    bloom(
      Offset(
        w * (1.05 + 0.08 * math.cos(phase + 1.3)),
        w * (0.02 + 0.07 * math.sin(phase + 0.7)),
      ),
      w * (1.0 + 0.06 * math.cos(phase * 2 + 0.4)),
      b,
    );
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.a != a || old.b != b || old.t != t;
}

/// A frosted card floating over the screen wash.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.card),
    this.radius = Radii.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: p.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D111627),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      // ponytail: no BackdropFilter. Blurring a smooth gradient looks the
      // same as not blurring it, and a blur would re-run every frame behind
      // the moving wash. Add it back only if cards ever sit over imagery.
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          color: p.glass,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

enum PillTone { neutral, tinted, outline, dashed }

/// Small rounded label: status chips, "On pace", "Not available".
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.tone = PillTone.neutral,
    this.tint,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final PillTone tone;

  /// Fill for [PillTone.tinted], usually a family's `track` colour.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    final fill = switch (tone) {
      PillTone.neutral => p.chip,
      PillTone.tinted => tint ?? p.chip,
      PillTone.outline || PillTone.dashed => Colors.transparent,
    };
    final textColor = tone == PillTone.outline || tone == PillTone.dashed
        ? p.ink2
        : p.ink;
    Widget pill = Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 7, 4, 10, 4),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: tone == PillTone.outline ? Border.all(color: p.line) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: t.chip.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (tone == PillTone.dashed) {
      pill = CustomPaint(painter: _DashedPillBorder(p.ink3), child: pill);
    }
    return pill;
  }
}

class _DashedPillBorder extends CustomPainter {
  _DashedPillBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    ).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillBorder old) => old.color != color;
}

/// A number with smaller unit text, e.g. "7h 18m" or "58 bpm".
/// Pass parts as (number, unit) pairs.
class MetricText extends StatelessWidget {
  const MetricText(
    this.parts, {
    super.key,
    this.style,
    this.unitColor,
    this.semanticsLabel,
  });

  final List<(String, String)> parts;
  final TextStyle? style;

  /// Defaults to the muted ink.
  final Color? unitColor;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final s = style ?? context.type.metric;
    final unit = context.type
        .unit(s)
        .copyWith(color: unitColor ?? context.palette.ink2);
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, (n, u)) in parts.indexed) ...[
            TextSpan(text: i == 0 ? n : ' $n', style: s),
            if (u.isNotEmpty) TextSpan(text: u, style: unit),
          ],
        ],
      ),
      semanticsLabel: semanticsLabel,
    );
  }
}

/// Round icon button used in screen headers.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: p.chip,
        foregroundColor: p.ink,
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// A row of mutually exclusive options, e.g. Today / 7D / 30D / 90D / Year.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.type;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(Radii.button - 2),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: Motion.quick,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: v == selected ? p.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.button - 5),
                      boxShadow: v == selected && !p.isDark
                          ? const [
                              BoxShadow(
                                color: Color(0x14111627),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      labelOf(v),
                      textAlign: TextAlign.center,
                      style: t.chip.copyWith(
                        color: v == selected ? p.ink : p.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
