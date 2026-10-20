import 'package:flutter/material.dart';

import '../core/format.dart';
import 'theme.dart';

/// Zero when the user has asked the system to reduce motion.
Duration motion(BuildContext context, Duration d) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;

/// Fades and lifts its child in once, the first time it appears.
/// [index] staggers siblings.
class Entrance extends StatelessWidget {
  const Entrance({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  static const _step = 70;
  static const _base = 420;

  @override
  Widget build(BuildContext context) {
    final total = _base + index * _step;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, Duration(milliseconds: total)),
      curve: Interval(index * _step / total, 1, curve: Curves.easeOutCubic),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, (1 - v) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A whole number that counts up to [value], and from the old value to the
/// new one when it changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(
    this.value, {
    super.key,
    this.style,
    this.format = thousands,
  });
  final int value;
  final TextStyle? style;
  final String Function(num) format;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: format(value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: motion(context, const Duration(milliseconds: 900)),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Text(format(v.round()), style: style),
        ),
      ),
    );
  }
}

/// Sweeps a soft highlight across its child. Wrap skeleton [Bone]s in one
/// Shimmer so they shine together.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still && _c.isAnimating) _c.stop();
    if (!still && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final p = context.palette;
    final base = p.isDark ? p.chip : p.line;
    final light = Color.lerp(
      base,
      p.isDark ? p.ink : p.surface,
      p.isDark ? 0.1 : 0.75,
    )!;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: [base, light, base],
          stops: const [0.35, 0.5, 0.65],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: _Slide(_c.value),
        ).createShader(rect),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

/// A placeholder block for skeleton layouts.
class Bone extends StatelessWidget {
  const Bone({super.key, this.width, required this.height, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: p.isDark ? p.chip : p.line,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A sync icon that spins while [spinning] is true.
class SpinningIcon extends StatefulWidget {
  const SpinningIcon(
    this.icon, {
    super.key,
    required this.spinning,
    this.size,
    this.color,
  });
  final IconData icon;
  final bool spinning;
  final double? size;
  final Color? color;

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SpinningIcon old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final spin = widget.spinning && !MediaQuery.disableAnimationsOf(context);
    if (spin && !_c.isAnimating) _c.repeat();
    if (!spin && _c.isAnimating) _c.animateTo(1).then((_) => _c.reset());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: Icon(widget.icon, size: widget.size, color: widget.color),
  );
}
