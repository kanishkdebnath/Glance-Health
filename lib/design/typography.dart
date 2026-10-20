import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'palette.dart';

/// Font families. Swap these two names (and the files in pubspec.yaml) to
/// change the app's typefaces.
abstract final class Fonts {
  static const display = 'Outfit';
  static const text = 'Figtree';
}

/// The type scale. Display weights stay at 400–500 so screens stay calm.
@immutable
class GlanceType {
  GlanceType(GlancePalette p)
    : hero = _display(56, 400, p.ink, height: 1, spacing: -1.4),
      title = _display(30, 500, p.ink, height: 1.1, spacing: -0.6),
      headline = _display(22, 500, p.ink, height: 1.25, spacing: -0.2),
      metric = _display(30, 500, p.ink, height: 1, spacing: -0.3),
      metricSmall = _display(20, 500, p.ink, height: 1.1),
      body = _text(15, 400, p.ink, height: 1.45),
      bodyMuted = _text(15, 400, p.ink2, height: 1.45),
      small = _text(13, 400, p.ink2, height: 1.35),
      label = _text(13, 600, p.ink2),
      eyebrow = _text(12, 600, p.ink2, spacing: 1.0),
      chip = _text(12, 600, p.ink),
      chart = _text(11, 500, p.ink2),
      tab = _text(11, 600, p.ink3);

  final TextStyle hero;
  final TextStyle title;
  final TextStyle headline;
  final TextStyle metric;
  final TextStyle metricSmall;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle small;
  final TextStyle label;

  /// Use with uppercase text.
  final TextStyle eyebrow;
  final TextStyle chip;
  final TextStyle chart;
  final TextStyle tab;

  /// Smaller unit text next to a number, e.g. the "h" in 7h 18m.
  TextStyle unit(TextStyle number) => number.copyWith(
    fontSize: (number.fontSize ?? 16) * 0.5,
    fontWeight: FontWeight.w500,
    fontVariations: const [FontVariation.weight(500)],
    letterSpacing: 0,
  );

  static TextStyle _display(
    double size,
    double weight,
    Color color, {
    double? height,
    double spacing = 0,
  }) => _style(
    Fonts.display,
    size,
    weight,
    color,
    height: height,
    spacing: spacing,
  );

  static TextStyle _text(
    double size,
    double weight,
    Color color, {
    double? height,
    double spacing = 0,
  }) =>
      _style(Fonts.text, size, weight, color, height: height, spacing: spacing);

  // Variable fonts: set both the weight (for fallback fonts) and the wght axis.
  static TextStyle _style(
    String family,
    double size,
    double weight,
    Color color, {
    double? height,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[(weight ~/ 100 - 1).clamp(0, 8)],
    fontVariations: [FontVariation.weight(weight)],
    color: color,
    height: height,
    letterSpacing: spacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
