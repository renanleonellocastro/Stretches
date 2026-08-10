# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Refreshed the whole UI into one clean, cohesive design system: black
  background, a single calm-teal accent, a subtle frame ring with a small
  brand arc, consistent typography and rounded "pill" controls. Applied to
  the home, alarm prompt, save prompt, messages, duration/time pickers, the
  workout and the celebration screens.
- Reworked the workout screen so the stretch name, illustration and
  countdown never overlap.
- Illustrations now ship at eight per-resolution sizes (108–216 px) and each
  device pulls the bucket matching its screen, so the artwork is crisp and
  proportional from the 208x208 Forerunner 55 up to the 416x416 Venu 2.
  Poses are authored in a fixed logical space so nothing is clipped.
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
