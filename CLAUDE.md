# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Glance Health is a Flutter app (iOS + Android) that reads Fitbit Air data from Health Connect / Apple Health and shows a five-second daily check of steps, sleep and heart rate. It runs entirely on the device: no accounts, backend, analytics or network calls. Product decisions and risks live in `PROJECT_CONTEXT.md`; build status lives in `docs/PROGRESS.md`. The full visual design (every screen, sheet, toast, notification and widget) is the "Glance Health Design System" artifact: https://claude.ai/artifact/5Q1WSeAXDwyJUM3jEhHVKd

## Commands

```sh
flutter pub get
flutter analyze                      # must report "No issues found!"
flutter test                         # all tests
flutter test test/core_logic_test.dart --plain-name "baseline"   # one group/test
dart format lib test                 # 80-col default formatter
flutter build apk --release
dart run flutter_launcher_icons      # after changing assets/icon/app_icon.png; then
git checkout ios/Runner.xcodeproj/project.pbxproj   # undo the tool's bogus build-setting edit
```

`adb` is not on PATH on the dev machine; use `~/Library/Android/sdk/platform-tools/adb` (test phone: Galaxy S23 Ultra, Android 16). `flutter devices` may not list the phone until the adb server has been started with that binary. Install and launch:

```sh
ADB=~/Library/Android/sdk/platform-tools/adb
$ADB install -r build/app/outputs/flutter-apk/app-release.apk
$ADB shell monkey -p com.kanishkdebnath.glance_health -c android.intent.category.LAUNCHER 1
$ADB logcat -d | grep -E "FATAL EXCEPTION|OutOfMemory| E flutter"
```

Always check logcat after installing a release build: several bugs only showed up in release (R8) or on real Health Connect data.

## Architecture

Layers, with imports flowing downward only:

- `lib/app/` — wiring: Riverpod providers (`providers.dart`), the `AppTab` enum, go_router (`router.dart`).
- `lib/features/<area>/` — screens and their providers (home, steps, sleep, heart, settings). Each tab loads one `FutureProvider` of plain data; Steps and Heart use the shared `ui/detail_page.dart` frame.
- `lib/ui/` — widgets that combine domain types with the design system (`MetricCard`, `StatusPill`).
- `lib/design/` — the design system: no health logic. `palette.dart`, `typography.dart`, `tokens.dart`, `theme.dart`, `motion.dart`, `widgets.dart`, `charts/`.
- `lib/core/` — pure Dart domain: `health/` (data source interface, mock, Health Connect source, cache decorator, data check), `baseline.dart`, `pace.dart`, `steps_stats.dart` (streaks, bests), `sleep_stats.dart`, `goals.dart`, `format.dart`.

### Data flow

`dataModeProvider` (sample vs Health Connect, persisted) → `healthSourceProvider` returns `MockHealthDataSource` or `CachedHourlySource(HealthConnectSource)` → `homeSummaryProvider` calls `loadHomeSummary()` (a pure function, tested directly) and saves the result as JSON in SharedPreferences under `home.v1.<mode>` → `HomeScreen` shows `fresh.value ?? cachedHomeSummaryProvider` so launch is instant, with a shimmer skeleton only when there is no cache. Bump the `v1` in the cache key if the `HomeSummary` JSON shape changes.

Missing values are modelled, not nulls: `Reading<T>` is `Value` / `NoData` (some history, nothing today) / `Unsupported` (nothing in 30 days → UI says "Not available from your device"). Goals live in `goalsProvider` (SharedPreferences; no goal history yet). Status chips come from `compareToUsual()`: interquartile range of the last 30 days, `learning` until 14 days exist. Summary text (`features/home/headline.dart`) is rule-based and must stay observational: never medical, never "good/bad".

### Theming

Every colour comes from `GlancePalette` (light + dark constants); widgets read it via `context.palette` and text styles via `context.type`, both carried by the `GlanceTheme` ThemeExtension. Never hard-code a colour in a widget. A new theme is a new `GlanceThemeSet` returned from `themeSetProvider`. Metric hues are grouped by `MetricFamily` (steps, sleep, heart, cycle); adding a family (planned: training, for workout and strength logs in a later version) means a new enum value plus a `MetricColors` entry, and the exhaustive switches show what else needs updating. A new tab is one `AppTab` entry; the router and nav bar are generated from it.

Fonts (Outfit display, Figtree text) are bundled variable fonts. `GlanceType` sets both `fontWeight` and `fontVariations` because Flutter doesn't map weight to the `wght` axis on its own.

### Motion

Use `motion(context, duration)` for every animation so the system reduce-motion setting turns it off. `Wash` (screen background) and `Shimmer` repeat forever, so widget tests must set `tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true)` or `pumpAndSettle` never returns. Charts animate via `TweenAnimationBuilder` with `begin: 0`, which animates once on first show and then from old to new value.

## Health Connect gotchas (learned on the device)

- Never read raw `STEPS` or `HEART_RATE` over long ranges: a watch writes heart rate every few seconds and 30 days of samples ran the app out of memory (Java OOM, uncatchable from Dart). Steps use Health Connect's de-duplicated aggregate: `getHealthIntervalDataFromTypes` with a 1-day or 1-hour `interval` (seconds) returns all slices in one call. Heart rate has no min/max aggregate in the plugin, so `heartRateRange` reads one day per call and the cache keeps settled days.
- `requestAuthorization` can return false even when the user granted access (Android 16); check `hasPermissions` afterwards (`HealthConnectAccess.connect`).
- Active minutes have no Health Connect record type; they read as `Unsupported` for now.
- Android needs `FlutterFragmentActivity`, `minSdk 26`, read-only permissions in the manifest, the permissions-rationale intent filter and the `ViewPermissionUsageActivity` alias. Request only read access; the app never writes health data.
- `shared_preferences_android` is pinned to 2.4.28 in `dependency_overrides`: 2.5.0–2.5.1 (Pigeon JNI) crash release builds because R8 strips the Kotlin classes they look up by name. Lift the pin only after confirming a release build launches.
- Settings › Data check (`core/health/data_check.dart`) reports what Health Connect actually holds per type (counts, source apps, granularity, history depth) with a copyable report.

## Conventions

- Deliberate shortcuts are marked with `// ponytail:` comments that name the limit and the upgrade path (e.g. key-value caches that move to drift later).
- Commits are small and per module (`feat(design): …`, `fix(health): …`, `docs: …`). After each milestone, update `docs/PROGRESS.md` (dated log + phase table) and, if a product decision changed, `PROJECT_CONTEXT.md`.
- Out of scope for this release: workout and strength-training logs, recovery score, skin temperature, cloud sync, accounts, medical interpretation.
