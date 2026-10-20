# Glance-Health
Glance Health is a Flutter app for iOS and Android that turns Fitbit Air data into a five-second daily check: steps against a goal, last night's sleep, and resting heart rate, in plain language and a modern UI. It runs entirely on the device, with no accounts, cloud storage or API calls of its own.

## Run

```sh
flutter pub get
flutter run        # starts on sample data; connect Health Connect in Settings
flutter test
```

## Docs

- [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md): product decisions, platform findings, risks
- [docs/PROGRESS.md](docs/PROGRESS.md): what's built, what's next, dated log
- [CLAUDE.md](CLAUDE.md): engineering notes and gotchas (also read by Claude Code)
- [docs/brand/app-icon-prompt.md](docs/brand/app-icon-prompt.md): prompt for generating the app icon

## App icon

The source is `assets/icon/app_icon.png` (1024 × 1024, generated in Gemini from the prompt above, cropped to remove the Gemini watermark). After replacing it, regenerate the Android and iOS icons:

```sh
dart run flutter_launcher_icons
git checkout ios/Runner.xcodeproj/project.pbxproj   # the tool wrongly edits an unrelated build setting
```

Settings live under `flutter_launcher_icons:` in `pubspec.yaml`. On Android the whole square is inset inside the adaptive icon over `#265F82`, so launcher masks don't clip the G.

## How the code is organised

```
lib/
  design/     Design system. No health logic here.
    palette.dart        Every colour, light and dark
    typography.dart     Fonts and type scale
    tokens.dart         Spacing, radii, motion
    theme.dart          Builds ThemeData; context.palette / context.type
    metric_family.dart  Steps, sleep, heart, cycle: one hue each
    widgets.dart        Wash, GlassCard, Pill, MetricText…
    charts/             Custom-painted charts
  core/       Health data, baselines, pace, goals, formatting. No widgets.
    health/             HealthDataSource interface + mock
  ui/         Shared widgets that combine design and core (status pill, metric card)
  features/   One folder per screen or area (home, steps, sleep, heart, settings)
  app/        Providers, tabs, router
```

## Changing colours, fonts or themes

- **Colours:** edit `GlancePalette.light` / `.dark` in `lib/design/palette.dart`. Widgets and charts read colours only from the palette, never from literals.
- **A new theme** (e.g. high contrast): create another `GlanceThemeSet` in `theme.dart` and return it from `themeSetProvider`.
- **Fonts:** change the names in `Fonts` (`typography.dart`) and the files in `pubspec.yaml`. Fonts are bundled because the app never goes online.

## Adding a feature later (e.g. workouts, strength training)

1. Add a value to `MetricFamily` and a `MetricColors` entry to the palette. The compiler then points at every switch that needs the new family.
2. Add a data source for it in `core/` (its own interface, rather than growing `HealthDataSource`).
3. Add a folder under `features/`, and an entry in `AppTab` if it needs a tab.

The full design (every screen, sheet, toast, notification and widget) is in the [design document](https://claude.ai/artifact/5Q1WSeAXDwyJUM3jEhHVKd).
