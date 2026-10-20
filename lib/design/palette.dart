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
    required this.rimLight,
    required this.rimShade,
    required this.glassShadow,
    required this.glassSheen,
    required this.ray,
    required this.pattern,
    required this.seaTop,
    required this.seaDeep,
    required this.sky,
    required this.skyGlow,
    required this.particle,
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
  });

  final Brightness brightness;

  // Neutrals
  final Color background;
  final Color surface;

  /// Frosted card fill, drawn over the blurred screen behind it.
  final Color glass;

  /// Glass edge: bright where light hits (top left), [rimShade] opposite.
  final Color rimLight;
  final Color rimShade;

  /// Soft drop shadow under glass panels.
  final Color glassShadow;

  /// Light caught across the top of a glass panel.
  final Color glassSheen;

  /// Light rays falling across the screen background.
  final Color ray;

  /// Faint grain lines on the screen background.
  final Color pattern;

  /// Screen background: water near the surface, fading to the deep.
  final Color seaTop;
  final Color seaDeep;

  /// The sun (light) or moon (dark) seen from under water, and its halo.
  final Color sky;
  final Color skyGlow;

  /// Drifting particles that give the water depth.
  final Color particle;
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

  bool get isDark => brightness == Brightness.dark;

  static const light = GlancePalette(
    brightness: Brightness.light,
    background: Color(0xFFF2F4F8),
    surface: Color(0xFFFFFFFF),
    glass: Color(0x5CFFFFFF),
    rimLight: Color(0xF2FFFFFF),
    rimShade: Color(0x14111627),
    glassShadow: Color(0x1F1B2140),
    glassSheen: Color(0x73FFFFFF),
    ray: Color(0x66FFFFFF),
    pattern: Color(0x0F111627),
    seaTop: Color(0xFFE3F2F7),
    seaDeep: Color(0xFFDDE3EE),
    sky: Color(0xB3FFFCEB),
    skyGlow: Color(0x66FFF1BF),
    particle: Color(0x145A7A94),
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
      wash: Color(0x5C2F9E5B),
      wash2: Color(0x4D1FA99A),
    ),
    sleep: MetricColors(
      main: Color(0xFF5B5FD9),
      second: Color(0xFF8A6FF0),
      dim: Color(0xFFCFD1F6),
      track: Color(0xFFE6E7FA),
      wash: Color(0x4D5B5FD9),
      wash2: Color(0x478A6FF0),
    ),
    heart: MetricColors(
      main: Color(0xFFE0604E),
      second: Color(0xFFF28C5B),
      dim: Color(0xFFF5CCC5),
      track: Color(0xFFFBE6E2),
      wash: Color(0x52E0604E),
      wash2: Color(0x4DF28C5B),
    ),
    cycle: MetricColors(
      main: Color(0xFFB8479A),
      second: Color(0xFFE27BA8),
      dim: Color(0xFFEBC6E0),
      track: Color(0xFFF7E5F1),
      wash: Color(0x47B8479A),
      wash2: Color(0x4DE27BA8),
    ),
    stageAwake: Color(0xFFE3A653),
    stageRem: Color(0xFF8FB4F5),
    stageLight: Color(0xFF7584E6),
    stageDeep: Color(0xFF433DBF),
    phasePeriod: Color(0xFFB8479A),
    phaseFollicular: Color(0xFF4A6FE0),
    phaseOvulation: Color(0xFFC2851A),
    phaseLuteal: Color(0xFF25A08A),
  );

  static const dark = GlancePalette(
    brightness: Brightness.dark,
    background: Color(0xFF0A0E1A),
    surface: Color(0xFF151B2E),
    glass: Color(0x4D1A2138),
    rimLight: Color(0x40FFFFFF),
    rimShade: Color(0x0AFFFFFF),
    glassShadow: Color(0x8C000000),
    glassSheen: Color(0x17FFFFFF),
    ray: Color(0x14C8DCFF),
    pattern: Color(0x0BFFFFFF),
    seaTop: Color(0xFF0F2438),
    seaDeep: Color(0xFF05080F),
    sky: Color(0x73E6EDF8),
    skyGlow: Color(0x1FA9C3EC),
    particle: Color(0x17C3D8F5),
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
      wash: Color(0x733FA862),
      wash2: Color(0x5C2BBBA8),
    ),
    sleep: MetricColors(
      main: Color(0xFF7C82EC),
      second: Color(0xFF9C86F5),
      dim: Color(0xFF34386A),
      track: Color(0xFF1F2344),
      wash: Color(0x737C82EC),
      wash2: Color(0x619C86F5),
    ),
    heart: MetricColors(
      main: Color(0xFFE2654F),
      second: Color(0xFFF39867),
      dim: Color(0xFF5A2E2A),
      track: Color(0xFF35201F),
      wash: Color(0x6BE2654F),
      wash2: Color(0x57F39867),
    ),
    cycle: MetricColors(
      main: Color(0xFFC95AAE),
      second: Color(0xFFE58AB6),
      dim: Color(0xFF55294C),
      track: Color(0xFF321D30),
      wash: Color(0x66C95AAE),
      wash2: Color(0x52E58AB6),
    ),
    stageAwake: Color(0xFFD99B4C),
    stageRem: Color(0xFF88A9EE),
    stageLight: Color(0xFF6874DA),
    stageDeep: Color(0xFF4A44C4),
    phasePeriod: Color(0xFFB04A9E),
    phaseFollicular: Color(0xFF6684EC),
    phaseOvulation: Color(0xFFB98222),
    phaseLuteal: Color(0xFF2CAA8E),
  );
}
