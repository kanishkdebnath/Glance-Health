import 'package:flutter/material.dart';

import 'palette.dart';
import 'tokens.dart';
import 'typography.dart';

/// Carries the palette and type scale through the widget tree.
@immutable
class GlanceTheme extends ThemeExtension<GlanceTheme> {
  GlanceTheme(this.palette) : typeScale = GlanceType(palette);

  final GlancePalette palette;
  final GlanceType typeScale;

  @override
  GlanceTheme copyWith({GlancePalette? palette}) =>
      GlanceTheme(palette ?? this.palette);

  // ponytail: snaps halfway instead of blending every colour; add a full lerp
  // if theme switches ever need to animate.
  @override
  GlanceTheme lerp(GlanceTheme? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// A light and dark palette that ship together. Add another set here
/// (for example high contrast) to offer it as a theme.
@immutable
class GlanceThemeSet {
  const GlanceThemeSet({
    required this.name,
    required this.light,
    required this.dark,
  });
  final String name;
  final GlancePalette light;
  final GlancePalette dark;

  static const standard = GlanceThemeSet(
    name: 'Standard',
    light: GlancePalette.light,
    dark: GlancePalette.dark,
  );
}

ThemeData buildTheme(GlancePalette p) {
  final g = GlanceTheme(p);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: p.steps.main,
        brightness: p.brightness,
      ).copyWith(
        primary: p.ink,
        onPrimary: p.background,
        secondary: p.steps.main,
        surface: p.surface,
        onSurface: p.ink,
        onSurfaceVariant: p.ink2,
        outline: p.line,
        error: p.danger,
        inverseSurface: p.inverseSurface,
        onInverseSurface: p.onInverseSurface,
        scrim: p.scrim,
      );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    fontFamily: Fonts.text,
    textTheme: TextTheme(
      displayLarge: g.typeScale.hero,
      headlineMedium: g.typeScale.title,
      titleLarge: g.typeScale.headline,
      bodyLarge: g.typeScale.body,
      bodyMedium: g.typeScale.body,
      bodySmall: g.typeScale.small,
      labelLarge: g.typeScale.label,
    ),
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.inverseSurface,
      contentTextStyle: g.typeScale.body.copyWith(color: p.onInverseSurface),
      actionTextColor: p.isDark ? p.steps.main : p.steps.second,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.button),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBarrierColor: p.scrim,
      showDragHandle: true,
      dragHandleColor: p.line,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    extensions: [g],
  );
}

extension GlanceContext on BuildContext {
  GlanceTheme get _glance => Theme.of(this).extension<GlanceTheme>()!;
  GlancePalette get palette => _glance.palette;
  GlanceType get type => _glance.typeScale;
}
