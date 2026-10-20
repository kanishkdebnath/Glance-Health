# Progress

Living record of what is built, what is next, and what we learned. Update it after every milestone: add a dated entry to the log (newest first) and adjust the phase table. Product decisions belong in `PROJECT_CONTEXT.md`.

## Phases

Phases follow the release plan in `PROJECT_CONTEXT.md` §7.

| # | Phase | Status | Notes |
| --- | --- | --- | --- |
| 0 | Design | Done | Design System artifact: tokens, chart kit, every screen, state, sheet, toast, notification and widget; light and dark; cycle tracking with phases |
| 1 | Spike (Android) | In progress | Health Connect connected on a Galaxy S23 Ultra. Data check report pending. iOS spike not started |
| 2 | Data and baselines | Partly done | Data source interface, mock, Health Connect source, baseline / pace / headline logic, cached Home snapshot. drift storage not started |
| 3 | Core screens | Partly done | Home done (real data, cache, motion). Steps, Sleep, Heart are placeholders. Onboarding not started |
| 4 | Additional screens | Not started | HRV, SpO2, active minutes, weekly recap, sleep debt, suggested goals, cycle tracking |
| 5 | Widgets | Not started | |
| 6 | Notifications, settings, export | Partly done | Settings has Health Connect connect, sample-data switch, appearance, data check |
| 7 | Beta and store prep | Not started | |

## Built so far

- **Design system** (`lib/design/`): palette with light/dark constants and swappable theme sets, bundled Outfit + Figtree variable fonts, spacing/radius/motion tokens, frosted cards, pills, drifting gradient background, shimmer skeletons, count-up and entrance animations, all respecting reduce motion.
- **Charts**: steps gauge (270° arc, gradient, pace marker, animated sweep), goal bars (stepped weekday/weekend goal line), sparkline (usual-range band, draw-in).
- **Data**: `HealthDataSource` with `Reading` states (value / no data / not available); mock source matching the design numbers; Health Connect source (aggregate steps, sleep sessions with stages, resting HR, HRV, SpO2); hourly-steps cache for past days.
- **Home**: summary sentence, steps gauge with pace, sleep and resting HR cards with status and sparklines, active / HRV / SpO2 row, saved snapshot shown instantly on launch, "Updating…" status, pull to refresh, sample-data banner.
- **Settings**: Health Connect status and connect, sample-data switch, System / Light / Dark (persisted), Data check report.
- **Tests**: 14 (baseline, pace, headline, formatting, goals, Home summary from mock, unsupported metric, cache round trip, Home render in light and dark).

## Log

### 2026-10-20
- Home keeps its last values (SharedPreferences JSON) and refreshes in the background; shimmer skeleton on first launch; ring sweep, count-up, sparkline draw-in, staggered card entrances, slow drifting background. Removed the backdrop blur on cards (no visible difference over a smooth gradient, and it re-ran every frame behind the moving background).
- Past days' hourly steps cached: a Home refresh dropped from about 340 Health Connect calls to about 24.
- Fixed: app ran out of memory on launch reading 30 days of raw heart-rate samples. Presence checks now use the steps aggregate and a one-day heart-rate window; Data check limits steps and heart rate to 24 hours.
- Fixed: `requestAuthorization` reported failure after the user allowed access; now re-checks granted permissions.
- Fixed: release builds crashed on start because `shared_preferences_android` 2.5.x (Pigeon JNI) breaks under R8; pinned 2.4.28.
- Health Connect connected on the test phone (read only): steps, sleep, heart rate, resting HR, HRV, SpO2, exercise, menstruation, history. Background reads not granted yet.
- First real-data readings: steps on pace, sleep 6h 23m (Fitbit app shows 6h 26m; check awake-time counting against the Data check report), resting HR 73, HRV 62 ms. SpO2 and active minutes not available. Chips show "Learning your usual" until 14 days of history.
- Flutter project created (`com.kanishkdebnath.glance_health`); design system, Home, tab shell, settings and tests built; app named "Glance Health" on both platforms.
- Design document finished, including cycle tracking with estimated phases (decision recorded in `PROJECT_CONTEXT.md`).

## Open questions and known issues

- Data check report from the test phone still to be reviewed: which apps write steps and sleep (Fitbit, Samsung Health, Galaxy Watch), granularity, history depth.
- Sleep minutes differ slightly from the Fitbit app (6h 23m vs 6h 26m).
- Active minutes need a source (exercise sessions, or "not available" permanently).
- Background read permission is needed before widgets can refresh on their own.
- `flutter doctor`: Android cmdline-tools missing and SDK licences not accepted (builds work regardless).

## Next

1. Review the Data check report; settle the step-source rule and the sleep calculation.
2. Build Steps, Sleep and Heart screens with the remaining charts (sleep stages, schedule, HR range, year heatmap).
3. drift storage for goals, goal history and daily aggregates; move the key-value caches into it.
4. Onboarding flow, then the iOS spike on a physical iPhone.
