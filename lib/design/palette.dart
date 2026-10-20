import 'package:flutter/material.dart';

/// Colours for one metric family (steps, sleep, heart, cycle…).
@immutable
class MetricColors {
  const MetricColors({
    required this.main,
    required this.second,
    required this.dim,
    required this.track,
    required this.wash,
    required this.wash2,
  });

  /// Marks, icons, met bars.
  final Color main;

  /// Gradient partner for [main] (an analogous hue).
  final Color second;

  /// Unmet bars, range stems.
  final Color dim;

  /// Ring background and tinted chip fill.
  final Color track;

  /// The two soft blooms painted behind a screen of this family.
  final Color wash;
  final Color wash2;

  LinearGradient get gradient => LinearGradient(colors: [main, second]);
}

/// Every colour the app uses. Nothing else in the app hard-codes a colour.
///
/// To re-skin the app, edit [light] and [dark] or create a new palette and
/// register it in `themes.dart`.
@immutable
class GlancePalette {
  const GlancePalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.glass,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.chip,
    required this.band,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.warning,
    required this.danger,
    required this.steps,
    required this.sleep,
    required this.heart,
    required this.cycle,
    required this.stageAwake,
    required this.stageRem,
    required this.stageLight,
    required this.stageDeep,
    required this.phasePeriod,
    required this.phaseFollicular,
    required this.phaseOvulation,
    required this.phaseLuteal,
    required this.night,
    required this.onNight,
    required this.onNight2,
  });

  final Brightness brightness;

  // Neutrals
  final Color background;
  final Color surface;

  /// Frosted card fill, drawn over the screen wash.
  final Color glass;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color chip;

  /// "Usual range" band behind trend charts.
  final Color band;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;

  // Semantic (never used as a metric colour)
  final Color warning;
  final Color danger;

  // Metric families
  final MetricColors steps;
  final MetricColors sleep;
  final MetricColors heart;
  final MetricColors cycle;

  // Sleep stages: ordinal, darker = deeper. Awake sits outside the scale.
  final Color stageAwake;
  final Color stageRem;
  final Color stageLight;
  final Color stageDeep;

  // Cycle phases
  final Color phasePeriod;
  final Color phaseFollicular;
  final Color phaseOvulation;
  final Color phaseLuteal;

  /// Sleep header gradient, top to bottom. Stays dark in both themes.
  final List<Color> night;

  /// Text on the night gradient: primary and muted.
  final Color onNight;
  final Color onNight2;

  bool get isDark => brightness == Brightness.dark;

  static const light = GlancePalette(
    brightness: Brightness.light,
    background: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    glass: Color(0xCCFFFFFF),
    ink: Color(0xFF111627),
    ink2: Color(0xFF5A627A),
    ink3: Color(0xFF9AA1B4),
    line: Color(0xFFE3E6ED),
    chip: Color(0xFFEDEFF5),
    band: Color(0xFFE9ECF3),
    scrim: Color(0x6B111627),
    inverseSurface: Color(0xFF151A2B),
    onInverseSurface: Color(0xFFF1F3FA),
    warning: Color(0xFFC98A2E),
    danger: Color(0xFFC9452F),
    steps: MetricColors(
      main: Color(0xFF2F9E5B),
      second: Color(0xFF1FA99A),
      dim: Color(0xFFBCE2C8),
      track: Color(0xFFE0F1E5),
      wash: Color(0x422F9E5B),
      wash2: Color(0x381FA99A),
    ),
    sleep: MetricColors(
      main: Color(0xFF5B5FD9),
      second: Color(0xFF8A6FF0),
      dim: Color(0xFFCFD1F6),
      track: Color(0xFFE6E7FA),
      wash: Color(0x385B5FD9),
      wash2: Color(0x338A6FF0),
    ),
    heart: MetricColors(
      main: Color(0xFFE0604E),
      second: Color(0xFFF28C5B),
      dim: Color(0xFFF5CCC5),
      track: Color(0xFFFBE6E2),
      wash: Color(0x3DE0604E),
      wash2: Color(0x38F28C5B),
    ),
    cycle: MetricColors(
      main: Color(0xFFB8479A),
      second: Color(0xFFE27BA8),
      dim: Color(0xFFEBC6E0),
      track: Color(0xFFF7E5F1),
      wash: Color(0x33B8479A),
      wash2: Color(0x38E27BA8),
    ),
    stageAwake: Color(0xFFE3A653),
    stageRem: Color(0xFF8FB4F5),
    stageLight: Color(0xFF7584E6),
    stageDeep: Color(0xFF433DBF),
    phasePeriod: Color(0xFFB8479A),
    phaseFollicular: Color(0xFF4A6FE0),
    phaseOvulation: Color(0xFFC2851A),
    phaseLuteal: Color(0xFF25A08A),
    night: [Color(0xFF121838), Color(0xFF28316F), Color(0xFF56609F)],
    onNight: Color(0xFFF1F2FB),
    onNight2: Color(0xFFB8BDE6),
  );

  static const dark = GlancePalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0E1A),
    surface: Color(0xFF151B2E),
    glass: Color(0xB8181F34),
    ink: Color(0xFFEDF0F7),
    ink2: Color(0xFF99A1B8),
    ink3: Color(0xFF5E6680),
    line: Color(0xFF242B42),
    chip: Color(0xFF1F2740),
    band: Color(0xFF1C2338),
    scrim: Color(0x8C000000),
    inverseSurface: Color(0xFFF4F5FA),
    onInverseSurface: Color(0xFF111627),
    warning: Color(0xFFE3A653),
    danger: Color(0xFFE2654F),
    steps: MetricColors(
      main: Color(0xFF3FA862),
      second: Color(0xFF2BBBA8),
      dim: Color(0xFF24513A),
      track: Color(0xFF1B3127),
      wash: Color(0x573FA862),
      wash2: Color(0x422BBBA8),
    ),
    sleep: MetricColors(
      main: Color(0xFF7C82EC),
      second: Color(0xFF9C86F5),
      dim: Color(0xFF34386A),
      track: Color(0xFF1F2344),
      wash: Color(0x577C82EC),
      wash2: Color(0x479C86F5),
    ),
    heart: MetricColors(
      main: Color(0xFFE2654F),
      second: Color(0xFFF39867),
      dim: Color(0xFF5A2E2A),
      track: Color(0xFF35201F),
      wash: Color(0x52E2654F),
      wash2: Color(0x3DF39867),
    ),
    cycle: MetricColors(
      main: Color(0xFFC95AAE),
      second: Color(0xFFE58AB6),
      dim: Color(0xFF55294C),
      track: Color(0xFF321D30),
      wash: Color(0x4DC95AAE),
      wash2: Color(0x38E58AB6),
    ),
    stageAwake: Color(0xFFD99B4C),
    stageRem: Color(0xFF88A9EE),
    stageLight: Color(0xFF6874DA),
    stageDeep: Color(0xFF4A44C4),
    phasePeriod: Color(0xFFB04A9E),
    phaseFollicular: Color(0xFF6684EC),
    phaseOvulation: Color(0xFFB98222),
    phaseLuteal: Color(0xFF2CAA8E),
    night: [Color(0xFF121838), Color(0xFF28316F), Color(0xFF56609F)],
    onNight: Color(0xFFF1F2FB),
    onNight2: Color(0xFFB8BDE6),
  );
}
