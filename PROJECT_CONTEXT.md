# Glance Health: project context and decisions

Last updated: 2026-10-20. This file records product decisions, findings and risks. Build progress is in `docs/PROGRESS.md`. The full PRD lives in a claude.ai doc titled "PRD: Glance Health (Fitbit Air companion app)" (sections 1 to 13); this file summarises it and records what has happened since.

## 1. What we are building

A Flutter app for iOS and Android that turns Fitbit Air data into a five-second daily check: steps against a goal, last night's sleep, and resting heart rate, in plain language and a modern, minimal UI. It runs entirely on the device, with no accounts, cloud storage, backend or API calls of its own. Home screen widgets are a primary surface.

Target user: a working professional who wants to glance at the app (or a widget) and move on. Not athlete-level.

## 2. Key technical findings (verified via search, Oct 2026)

- **Fitbit Air** is Google's screenless band (announced May 2026). Its data is exposed through the **Google Health API**, which replaces the legacy Fitbit Web API.
- The legacy **Fitbit Web API** loses support on Sept 30, 2026 and is turned off on **Oct 30, 2026**. Do not build on it. Old Fitbit OAuth tokens cannot be migrated.
- All Google Health API scopes are **Restricted** and need a privacy and security review. We avoid this entirely by staying on-device.
- Fitbit Air syncs over Bluetooth to the **Google Health (Fitbit) app**, which can write into **Health Connect** (Android) and **Apple Health** (iOS), per data category. Our app reads from those stores. The Google Health app must stay installed as the intermediary; the band's sync protocol is not public, so direct Bluetooth pairing is not possible.
- Google's Apple Health sync is new and has reported open bugs, so iOS is the riskier path.

## 3. Architecture decisions

| Area | Decision |
| --- | --- |
| Data source | On-device only: Health Connect (Android), Apple Health / HealthKit (iOS), via the Flutter `health` package |
| Networking | None. No backend, no cloud, no analytics that send health data |
| Local storage | `drift` (SQLite): daily aggregates, hourly step buckets, nightly sleep sessions, nightly HRV and SpO2, goal history. No minute-level heart rate |
| Abstraction | `HealthDataSource` interface so a mock source can be used for development and tests |
| State management | Riverpod |
| Charts | Custom-drawn or a light library; mostly rings, bars, heatmaps and a sleep stage bar |
| Widgets | Native: Jetpack Glance or AppWidgetProvider (Kotlin) on Android, WidgetKit (SwiftUI) on iOS, bridged with `home_widget`. Widgets never query the health stores; the Flutter app writes a small summary to shared storage (SharedPreferences on Android, App Group on iOS) |
| Notifications | Local only |
| Summaries | Rule-based text generated on the device, compared against the user's own 30-day baseline. No AI service |

## 4. Product decisions

- **Single final release.** Everything in the PRD ships together on both platforms. Nothing is deferred to a later version.
- **Steps is the hero metric**, with goals: default 8,000, optional weekday and weekend goals, goal history (changes apply going forward), streaks, personal bests, suggested goals after 14 days, views for today, 7, 30, 90 days and a year.
- **Included metrics:** steps, sleep (duration, stages, bed and wake time, sleep target, sleep debt, consistency), resting heart rate, day heart rate range, HRV, SpO2, active minutes.
- **Home screen:** headline summary sentence, large steps ring with pace hint, Sleep and Heart cards with status chips (Below usual / Typical / Above usual) and 7-day sparklines, a compact row for active minutes, HRV and SpO2, and a "last synced" time.
- **Widgets:** small (steps ring, switchable to sleep or resting HR), medium (steps ring, sleep, resting HR, 7-day goal bars), large (weekly recap), iOS lock screen widgets. Each shows "updated at" and deep-links into the app.
- **Notifications:** goal reached, optional evening nudge, optional weekly recap. All local, each switchable.
- **Other:** weekly recap, CSV export via the share sheet, light and dark themes, onboarding that explains the data path.
- **Tone:** friendly but factual, observational wording only, never medical.
- **Cycle tracking (added 20 Oct 2026):** optional, off by default, available to anyone (no gender question). Reads menstruation records from Health Connect / Apple Health and lets the user log period days in the app (stored locally only; the app stays read-only towards the health stores). After two logged cycles it estimates the next period start (as a range) and the four phases (period, follicular, ovulation, luteal), each in its own colour. Ovulation is placed about 14 days before the next expected period (calendar method) and is always labelled "estimated". No fertile-window, conception or pregnancy wording; a standing note says estimates can't be used to prevent or plan a pregnancy. Hidden from widgets, notifications and CSV export unless the user turns each on; reminder text hidden on the lock screen by default; separate delete. Fitbit Air doesn't sense periods, so the spike should check whether the Google Health app shares cycle logs.
- **Metrics that are unavailable** from the device show a "not available from your device" state instead of being removed.
- **Not included:** composite recovery score, skin temperature, respiratory rate, workouts and GPS, minute-level heart rate curves, accounts, cloud sync, social features, medical interpretation.

## 5. Defaults still to confirm

| Decision | Current default |
| --- | --- |
| Goal streak rule | One grace day per week, shown alongside "goal met X of last 7 days" |
| Status wording | Below usual, Typical, Above usual |
| Default goals | 8,000 steps, 7.5 hours sleep, both editable |
| Summary tone | Friendly but factual |
| Whether the "not included" list stays out | Confirmed out unless changed |
| Step source rule (phone vs band, to avoid double counting) | Open: decide after the spike |

## 6. Known risks and constraints

- Fitbit Air metrics may not all reach Health Connect or Apple Health at usable granularity. The spike decides this.
- iOS hides read-permission denial ("no data" and "denied" look the same). The UI must handle both with one message.
- iOS health data is unavailable while the phone is locked, which affects background sync and widgets.
- Health Connect reads only about 30 days before the first permission grant by default. The app archives locally from first install and requests the history permission on Android.
- Android background reads need a separate Health Connect permission.
- Widget refresh is throttled on both platforms. Always show "updated at".
- Duplicate step sources (phone plus band) can inflate goal progress.
- Store review: Google Play health data declaration, privacy policy, App Store HealthKit justification. Start these early.
- Cycle data is special-category data under GDPR and sensitive under the DPDP Act. Update the privacy policy, the Play health data declaration and the App Store HealthKit justification to cover it.
- Privacy: encrypt local storage where possible, exclude from cloud backups, request minimum permissions. For Indian and EU users, follow DPDP Act 2023 and GDPR consent rules.

## 7. Release plan (rough, one developer, about 18 weeks)

1. Spike on Android and a physical iPhone (about 1 week). Gate: available metrics, granularity and the step-source rule documented.
2. Data and baselines (about 3 weeks).
3. Core screens: Home, Steps and goals, Sleep, Heart, onboarding (about 4 weeks).
4. Additional screens: HRV, SpO2, active minutes, weekly recap, sleep debt, suggested goals (about 2 weeks).
5. Widgets on both platforms (about 3 weeks).
6. Notifications, settings, export (about 2 weeks).
7. Beta and store prep (about 3 weeks).
8. Release on both stores together.

Android is built first for convenience, but nothing ships until iOS passes the same gates.

## 8. Progress and next steps

Tracked in `docs/PROGRESS.md` (phase table, dated log, open issues, next steps). Engineering guidance for Claude Code is in `CLAUDE.md`.

- Workout and strength-training logs are planned for a later version, not this one. The code leaves room for them (new `MetricFamily`, own data source, own feature folder).

## 9. Notes for Claude Code

- Keep the app fully offline: no HTTP client dependencies and no analytics SDKs that transmit data.
- Keep widget payloads small (today's totals, a 7-day series, a status label, a timestamp).
- Summary wording must stay observational, never imply illness or give medical advice.
- Verify `health` package APIs against the installed version (currently 13.3.2) before relying on older notes.
- The shell used for the planning session could not delete files in `~/Developer`, so any cleanup (the `.partial-clone` folder) is manual.
