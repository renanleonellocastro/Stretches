# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **52 newer Garmin devices** are now supported (80 in total): fēnix 7 Pro,
  fēnix 8 / 8 Solar / 8 Pro / E, fēnix 9 / 9 Pro, Epix 2 / Epix Pro, Enduro 3,
  Forerunner 70 / 165 / 170 / 265 / 570 / 965 / 970 / 945 LTE, Venu 3 / 4 /
  X1, Vívoactive 5 / 6, Instinct 3 AMOLED / Crossover AMOLED, MARQ 2,
  Descent Mk3 and D2 Mach 1 / 2 (issue #13).
- Three new illustration size buckets (213, 219 and 224 px) for the 454x454,
  466x466 and 448x486 AMOLED screens.

### Changed

- CI now compiles the fēnix 8 47mm and the rectangular Venu X1 in addition to
  the previous three representative devices.

## [1.0.3] - 2026-08-10

### Fixed

- **Beeper-less devices (Venu / Venu Sq / Vívoactive families) no longer
  crash when a tone would play**: TONE_* constants don't exist on those
  watches and are now only referenced behind capability guards.
- FIT lap name field enlarged to 32 bytes and writes made fault-tolerant;
  four Spanish/French stretch names that overflowed the old 24-byte field
  were shortened. A test now enforces every translation fits.
- Custom FIT fields (stretch count, per-lap stretch name and hold time) now
  carry the required resource metadata, so they actually **display in Garmin
  Connect** — previously they were recorded but invisible.
- End-workout confirmation is order-independent: the decision is applied
  after the dialog is dismissed, so the save prompt can no longer be lost.
- Deleting a schedule rebuilds the schedules menu correctly (the stale list
  could act on the wrong entry after indices shifted).
- The random stretch order is now seeded before shuffling (cold starts used
  to produce the same "random" order every time).

### Changed

- Pausing a workout now also pauses the FIT activity timer, so paused time
  is not counted in the saved activity.
- Touch devices: tapping an option row highlights it and tapping again
  confirms (previously a tap triggered whatever was highlighted — tapping
  "Skip" could start a workout); pickers accept tap zones (top +, bottom −,
  middle confirm).
- Performance: the stretch catalog is cached (was rebuilt per lookup) and
  the English i18n fallback no longer duplicates the active-language table.

### Added

- `scripts/audit_api_usage.py` — CI gate verifying every Toybox symbol used
  exists on all 28 target devices (the class of bug behind most on-device
  crashes so far).
- Test suite expanded from 35 to **125 tests**, including on-simulator
  integration tests: real Storage round-trips, all 34 illustrations load,
  complete i18n tables for six languages, FIT name-length constraints.
- `docs/TESTING.md` — the full test strategy plus the scripted on-device
  pass covering what simulators cannot verify.

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
