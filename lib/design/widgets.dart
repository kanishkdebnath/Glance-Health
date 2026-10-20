import 'dart:math' as math;

import 'dart:ui' show ImageFilter;

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
    duration: const Duration(seconds: 60),
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
                  painter: _SeaPainter(_drift, widget.colors, p),
                ),
              ),
            ),
          ),
          // Static grain: painted once, never repainted by the drift.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PatternPainter(p.pattern)),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// The screen background: looking up from under water. Depth darkens
/// downward, the sun (light theme) or moon (dark theme) wobbles at the
/// surface, light shafts fall from it, and particles drift up slowly. The
/// tab's two colour blooms sit in the water.
class _SeaPainter extends CustomPainter {
  _SeaPainter(this.t, this.colors, this.p) : super(repaint: t);
  final Animation<double> t;
  final MetricColors colors;
  final GlancePalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t.value * 2 * math.pi;
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Depth.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.seaTop, p.seaDeep],
          stops: const [0, 0.75],
        ).createShader(rect),
    );

    void bloom(Offset centre, double radius, Color c) => canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [c, c.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );

    // A bloom carried by a current: it wanders, stretches into an ellipse
    // and swells and shrinks. Whole-number harmonics keep the loop seamless.
    void current(Offset centre, double radius, double sx, double sy, Color c) {
      canvas
        ..save()
        ..translate(centre.dx, centre.dy)
        ..scale(sx, sy);
      canvas.drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [c, c.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius)),
      );
      canvas.restore();
    }

    current(
      Offset(
        w * (0.05 + 0.22 * math.sin(phase * 2) + 0.06 * math.sin(phase * 5)),
        h * (0.12 + 0.08 * math.cos(phase * 3)),
      ),
      w * (0.95 + 0.18 * math.sin(phase * 4 + 0.5)),
      1 + 0.18 * math.sin(phase * 3),
      1 - 0.12 * math.sin(phase * 3 + 0.8),
      colors.wash,
    );
    current(
      Offset(
        w *
            (0.95 +
                0.2 * math.cos(phase * 2 + 1.3) +
                0.05 * math.sin(phase * 7)),
        h * (0.28 + 0.1 * math.sin(phase * 3 + 0.7)),
      ),
      w * (0.9 + 0.2 * math.cos(phase * 4 + 0.4)),
      1 - 0.15 * math.cos(phase * 2),
      1 + 0.2 * math.sin(phase * 4 + 1.1),
      colors.wash2,
    );
    // A third, deeper current mixing both colours, rising and falling.
    current(
      Offset(
        w * (0.5 + 0.3 * math.sin(phase + 2.1)),
        h * (0.55 + 0.12 * math.sin(phase * 2 + 0.3)),
      ),
      w * (0.8 + 0.15 * math.sin(phase * 3 + 2)),
      1.3 + 0.2 * math.sin(phase * 2),
      0.8,
      Color.lerp(
        colors.wash,
        colors.wash2,
        0.5 + 0.5 * math.sin(phase * 2),
      )!.withValues(alpha: colors.wash.a * 0.6),
    );

    // Sun or moon above the surface. The water bends it, so it breathes.
    final sky = Offset(w * (0.72 + 0.012 * math.sin(phase)), h * 0.02);
    final r = w * (p.isDark ? 0.09 : 0.12);
    // A wide, faint halo: the light spreads as it passes through water.
    bloom(sky, r * 9, p.skyGlow);
    final wobble = 0.05 * math.sin(phase * 3);
    canvas
      ..save()
      ..translate(sky.dx, sky.dy)
      ..scale(1 + wobble, 1 - wobble)
      ..drawCircle(
        Offset.zero,
        r,
        Paint()
          ..color = p.sky
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.9),
      )
      ..restore();

    // Light shafts from the sky, fanning down into the deep.
    final reach = h * 0.8;
    const beams = [
      (1.30, 0.05),
      (1.48, 0.03),
      (1.62, 0.07),
      (1.80, 0.04),
      (1.98, 0.06),
      (2.20, 0.035),
    ];
    for (final (i, (angle, spread)) in beams.indexed) {
      final a0 = angle + 0.04 * math.sin(phase + i * 1.7);
      final s = spread * (1 + 0.3 * math.sin(phase * 2 + i));
      final beam = Path()
        ..moveTo(sky.dx, sky.dy)
        ..lineTo(
          sky.dx + math.cos(a0 - s) * reach,
          sky.dy + math.sin(a0 - s) * reach,
        )
        ..lineTo(
          sky.dx + math.cos(a0 + s) * reach,
          sky.dy + math.sin(a0 + s) * reach,
        )
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
          ..shader = RadialGradient(
            colors: [
              p.ray.withValues(
                alpha: p.ray.a * (0.6 + 0.4 * math.cos(phase + i * 2.1)),
              ),
              p.ray.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: sky, radius: reach)),
      );
    }

    // Shimmer just under the surface.
    final shimmer = Paint()
      ..color = p.ray.withValues(alpha: p.ray.a * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    for (var k = 0; k < 3; k++) {
      final y0 = h * (0.025 + k * 0.03);
      final path = Path()..moveTo(0, y0);
      for (var x = 0.0; x <= w; x += 8) {
        path.lineTo(
          x,
          y0 + 3 * math.sin(x / (40 + k * 12) + phase * (k + 1) + k),
        );
      }
      canvas.drawPath(path, shimmer);
    }

    // Particles rising very slowly: one trip per minute-long loop.
    final dot = Paint()..color = p.particle;
    for (var i = 0; i < 28; i++) {
      final seed = math.sin(i * 12.9898) * 43758.5453;
      final fx = seed - seed.floorToDouble();
      final depth = 0.4 + 0.6 * ((i * 7) % 10) / 10;
      const trips = 1;
      final fy = (fx * 3.7 + t.value * trips) % 1.0;
      final x = w * fx + 6 * math.sin(phase * trips + i);
      final y = h * (1 - fy);
      canvas.drawCircle(
        Offset(x, y),
        0.8 + 1.4 * depth,
        dot..color = p.particle.withValues(alpha: p.particle.a * depth),
      );
    }
  }

  @override
  bool shouldRepaint(_SeaPainter old) =>
      old.colors != colors || old.p != p || old.t != t;
}

/// Curved vertical lines at uneven spacing, like wood grain or contour
/// lines, fading out down the screen. The lines share one flowing wave
/// with small differences each, so they bunch and spread like grain.
/// Static, so it's painted once.
class _PatternPainter extends CustomPainter {
  _PatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = size.height * 0.7;
    final screen = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = color;

    // Deterministic pseudo-random in 0–1, so the pattern never changes.
    double rand(int i) {
      final v = math.sin(i * 78.233 + 12.9898) * 43758.5453;
      return v - v.floorToDouble();
    }

    // Lines are drawn tilted about 20°, over a square big enough to cover
    // the screen after rotating, then faded out down the screen.
    final side = size.longestSide * 1.5;
    canvas
      ..saveLayer(screen, Paint())
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(-0.35)
      ..translate(-side / 2, -side / 2);
    var x0 = 0.0;
    for (var i = 0; x0 < side; i++) {
      x0 += 5 + 9 * rand(i); // dense, uneven spacing
      final own = rand(i + 500) * 2 * math.pi;
      final path = Path();
      for (var y = 0.0; y <= side; y += 6) {
        // Shared slow wave, a second shared ripple, and a small per-line drift.
        final dx =
            14 * math.sin(y / 140 + x0 / 90) +
            6 * math.sin(y / 53 + x0 / 40 + 1.3) +
            2.5 * math.sin(y / 31 + own);
        y == 0 ? path.moveTo(x0 + dx, y) : path.lineTo(x0 + dx, y);
      }
      canvas.drawPath(path, paint);
    }
    canvas
      ..restore()
      ..drawRect(
        screen,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
            stops: [0, fade / size.height],
          ).createShader(screen),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.color != color;
}

/// Frosted glass: blurs what's behind it, with a translucent fill, a rim
/// light along the edge and a soft shadow outside the shape. Every card,
/// list group and segmented control is built on this.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.radius = Radii.card,
    this.blur = 10,
    this.shadow = true,
    this.lift = 8,
    this.fill,
    this.floating = false,
  });

  final Widget child;
  final double radius;
  final double blur;
  final bool shadow;

  /// How far the shadow drops below the panel.
  final double lift;

  /// True for glass that sits above other glass (tab bar, sheets, toasts).
  /// Grouped blurs share one snapshot taken under the content, so floating
  /// glass takes its own and shows the cards beneath it.
  final bool floating;

  /// Defaults to the palette's glass.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    return CustomPaint(
      painter: shadow
          ? _GlassShadow(
              radius,
              p.glassShadow,
              lift: lift,
              softness: lift * 1.75,
            )
          : null,
      foregroundPainter: _RimLight(radius, p.rimLight, p.rimShade),
      child: ClipRRect(
        borderRadius: shape,
        child: _Backdrop(
          floating: floating,
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill ?? p.glass),
            position: DecorationPosition.background,
            child: DecoratedBox(
              decoration: BoxDecoration(
                // Sheen: light caught across the top of the glass.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.glassSheen, p.glassSheen.withValues(alpha: 0)],
                  stops: const [0, 0.45],
                ),
              ),
              // Lets ink splashes and list tiles paint on the glass.
              child: Material(type: MaterialType.transparency, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drop shadow drawn only outside the shape, so it never darkens the
/// translucent glass from underneath.
class _GlassShadow extends CustomPainter {
  _GlassShadow(this.radius, this.color, {this.lift = 8, this.softness = 14});
  final double radius;
  final Color color;
  final double lift;
  final double softness;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas
      ..save()
      ..clipPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(rrect.outerRect.inflate(60)),
          Path()..addRRect(rrect),
        ),
      )
      ..drawRRect(
        rrect.shift(Offset(0, lift)).deflate(lift / 2),
        Paint()
          ..color = color
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, softness),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_GlassShadow old) =>
      old.color != color || old.radius != radius;
}

/// A hairline that catches light on the top-left edge and fades out
/// towards the bottom right.
class _RimLight extends CustomPainter {
  _RimLight(this.radius, this.light, this.shade);
  final double radius;
  final Color light;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)).deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, light.withValues(alpha: 0), shade],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimLight old) =>
      old.light != light || old.shade != shade || old.radius != radius;
}

/// A glass card floating over the screen wash.
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
  Widget build(BuildContext context) => GlassSurface(
    radius: radius,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
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
    final glass = tone == PillTone.neutral || tone == PillTone.tinted;
    Widget pill = Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 7, 4, 10, 4),
      decoration: BoxDecoration(
        color: glass ? null : fill,
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
    if (glass) {
      pill = GlassSurface(
        radius: Radii.chip,
        blur: 8,
        shadow: false,
        fill: fill.withValues(alpha: fill.a * 0.6),
        child: pill,
      );
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

/// Gives a button depth: a rim light along the top-left edge and a soft
/// shadow underneath. Wrap any button whose shape has [radius] corners.
class Raised extends StatelessWidget {
  const Raised({super.key, required this.child, required this.radius});
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomPaint(
      painter: _GlassShadow(radius, p.glassShadow, lift: 4, softness: 8),
      foregroundPainter: _RimLight(radius, p.rimLight, p.rimShade),
      child: child,
    );
  }
}

/// Round glass button used in screen headers.
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
    return GlassSurface(
      radius: 22,
      blur: 12,
      lift: 4,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          fixedSize: const Size(44, 44),
        ),
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
    return GlassSurface(
      radius: Radii.button - 2,
      shadow: false,
      child: Padding(
        padding: const EdgeInsets.all(3),
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
                    child: _MaybeRaised(
                      raised: v == selected,
                      radius: Radii.button - 5,
                      child: AnimatedContainer(
                        duration: Motion.quick,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: v == selected
                              ? p.surface.withValues(
                                  alpha: p.isDark ? 0.14 : 0.85,
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(Radii.button - 5),
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
              ),
          ],
        ),
      ),
    );
  }
}

class _MaybeRaised extends StatelessWidget {
  const _MaybeRaised({
    required this.raised,
    required this.radius,
    required this.child,
  });
  final bool raised;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      raised ? Raised(radius: radius, child: child) : child;
}

/// Shows a sheet as a floating glass panel, inset from the screen edges.
Future<T?> showGlassSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  showDragHandle: false,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(Space.s),
      child: GlassSurface(
        radius: Radii.sheet,
        blur: 30,
        floating: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: Space.s + 2),
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: context.palette.ink3.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(Radii.chip),
              ),
            ),
            Flexible(child: builder(context)),
          ],
        ),
      ),
    ),
  ),
);

/// A short message in a floating glass bar.
void showGlassToast(BuildContext context, String message) {
  final t = context.type;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      content: GlassSurface(
        radius: Radii.button,
        blur: 24,
        floating: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.l,
            vertical: 14,
          ),
          child: Text(message, style: t.body),
        ),
      ),
    ),
  );
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({
    required this.floating,
    required this.filter,
    required this.child,
  });
  final bool floating;
  final ImageFilter filter;
  final Widget child;

  @override
  Widget build(BuildContext context) => floating
      ? BackdropFilter(filter: filter, child: child)
      : BackdropFilter.grouped(filter: filter, child: child);
}
