# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.2] - 2026-08-10

### Fixed

- **Crash when accepting the scheduled-reminder wake prompt.** The
  background-data callback pushed a view during the app's cold launch,
  before any view existed. It no longer touches the UI: the launch path
  shows the Start / Snooze / Skip prompt itself, and the home screen's poll
  picks up alarms flagged while the app was already open.
- Guard the workout backlight hold against BacklightOnTooLongException on
  devices that cap how long the backlight may stay forced on (e.g.
  Forerunner 55) — the screen now simply times out instead of crashing.

## [1.0.1] - 2026-08-10

### Added

- In-app **language switcher** (Settings → Language): choose English,
  Português, Español, Français, Deutsch or Italiano at any time. Defaults to
  the watch's system language. Backed by a runtime i18n table generated from
  the resource strings.
- Each completed stretch is now recorded as its own **lap**, tagged with the
  stretch name and hold time (custom FIT lap fields), for a richer Garmin
  Connect report.

### Changed

- **Reminders are reliable now.** They use a repeating 5-minute background
  poll that fires any enabled time which came due since the last check —
  self-healing and working even when the app is closed (alarms trigger within
  ~5 minutes of the set time) — replacing a one-shot temporal event that
  could fail to fire on some devices.
- The **backlight stays on** throughout a workout so the stretch remains
  readable.
- **"My stretches" opens instantly** — it reads the routine once instead of
  once per catalog item.

### Removed

- The on-screen heart-rate readout during workouts (it cluttered the small
  display). Heart rate is still recorded to the saved activity.

## [1.0.0] - 2026-08-10

### Added

- Catalog of 34 illustrated stretches across five muscle groups (neck,
  wrist/forearm, shoulder/chest, torso/back, legs), including twelve neck
  positions.
- Custom routine builder: pick any set of stretches, per-stretch duration
  (default 30 s); a starter routine is seeded on first launch.
- Daily schedules: any number of times, each individually enabled/disabled,
  with background reminders and a Start / Snooze 15 min / Skip prompt.
- Guided workout flow: 5-second countdown, per-stretch preview with a
  3-second lead-in, progress ring, pause and skip.
- Activity recording as Flexibility Training with heart rate, calories and
  time, plus a custom "stretches completed" FIT field; save or discard.
- Six languages: English, Português, Español, Français, Deutsch, Italiano.
- Support for 28 Garmin devices, including the Forerunner 55.
- Store listing copy (`docs/STORE_LISTING.md`), a marketing hero image and a
  README screenshot gallery.

### Changed

- A clean, cohesive design system: black background, a single calm-teal
  accent, a subtle frame ring with a small brand arc, consistent typography
  and rounded "pill" controls, across every screen.
- Stretch illustrations are friendly filled human figures (white body with a
  dark outline, orange two-piece outfit, hair and red motion arrows), shipped
  at nine per-resolution sizes (98–196 px) so the art is crisp and
  proportional from the 208×208 Forerunner 55 to the 416×416 Venu 2.
- Codebase-wide Clean Code pass: small, intention-revealing methods and
  comments kept only for the "why".

### Fixed

- Crash opening "My stretches" (and toggling Sound/Vibration or a schedule's
  Enabled flag) on devices without `CheckboxMenuItem` (e.g. Forerunner 55) —
  replaced with plain menu items that carry their state in the sub-label.
