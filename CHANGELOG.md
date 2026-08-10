# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Live heart rate on the workout screen, read from the recording session, as
  visible confirmation the session is being tracked (shown when a HR sensor
  is present).
- Store listing copy (`docs/STORE_LISTING.md`) and a marketing hero image
  (`docs/images/store-hero.png`), plus a README screenshot gallery.

### Changed

- Codebase-wide Clean Code pass: long methods decomposed into small,
  intention-revealing helpers (draw routines, menu delegates, scheduler and
  workout-engine phases); "what" comments removed, "why" comments kept.
  Behavior unchanged; all builds and unit tests still pass.

### Fixed

- **Crash opening "My stretches"** (and toggling Sound/Vibration or a
  schedule's Enabled flag): `CheckboxMenuItem` is not available on every
  target device (e.g. Forerunner 55). Replaced all checkbox/toggle items
  with plain `MenuItem`s whose sub-label shows the state ("In routine",
  "On"/"Off") and flips on tap — works on every device.
- Workout countdown number shrunk (FONT_NUMBER_MILD) so it stays inside the
  progress ring instead of spilling over it.
- Shortened the stretch-picker title to a single word ("Stretches") so it no
  longer wraps or clips in the Menu2 title bar.

### Changed

### Changed

- Refreshed the whole UI into one clean, cohesive design system: black
  background, a single calm-teal accent, a subtle frame ring with a small
  brand arc, consistent typography and rounded "pill" controls. Applied to
  the home, alarm prompt, save prompt, messages, duration/time pickers, the
  workout and the celebration screens.
- Reworked the workout screen so the stretch name, illustration and
  countdown never overlap.
- Redrew every stretch illustration as a friendly filled human figure (white
  body with a dark outline, orange two-piece outfit, hair and red motion
  arrows) in the spirit of a printed stretching chart — far clearer than the
  previous stick figures.
- Illustrations ship at nine per-resolution sizes (98–196 px); each device
  pulls the bucket matching its screen, so the artwork is crisp and
  proportional from the 208x208 Forerunner 55 up to the 416x416 Venu 2.
  Poses are authored in a fixed logical space so nothing is clipped.
- Workout screen layout fixed so the position ("2/8"), stretch name and
  countdown always stay inside the progress ring and never overlap the
  illustration or each other.
- The per-stretch 3-second lead-in now mirrors the initial 5-second
  get-ready: a big centered countdown with the stretch name and no progress
  ring, so you can read what's coming next.
- Muscle-group colors are now used only where meaningful (illustration
  borders and the in-workout progress ring), not as decoration.

## [1.0.0] - 2026-08-10

### Added

- Catalog of 34 stretches with clean line-art illustrations across five
  muscle groups (neck, wrist/forearm, shoulder/chest, torso/back, legs).
- Custom routine builder: pick any set of stretches, per-stretch duration
  (default 30 s).
- Daily schedules: any number of alarm times, each individually
  enabled/disabled, with background reminders (vibration + tone) and
  Start / Snooze 15 min / Skip prompt.
- Guided workout flow: 5-second countdown, per-stretch preview with
  illustration and 3-second lead-in, progress ring, pause and skip.
- Activity recording as Flexibility Training with heart rate, calories,
  laps per stretch and a custom "stretches completed" FIT field; save or
  discard at the end.
- Six languages: English, Portuguese, Spanish, French, German, Italian.
- Support for 28 Garmin devices, including Forerunner 55.
