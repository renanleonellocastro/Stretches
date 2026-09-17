# Testing Strategy

Three layers, from fully automated to on-watch verification. Connect IQ has
no code-coverage tooling and no on-device UI automation, so the strategy is:
**exhaustive automated tests for everything testable + a mechanical device
API audit + a scripted manual pass for hardware behavior.**

| Layer | What | Runs where | Gate |
|---|---|---|---|
| Unit + integration | Run No Evil suite (`source/tests/`) — pure logic **and** real Storage / resources / i18n on the simulator VM | `make test` (simulator) | Local before every commit; best-effort on CI |
| Device API audit | Every Toybox symbol used vs. every target device's API database | `python3 scripts/audit_api_usage.py` | CI (blocking) |
| Compile matrix | Type-check level 2, five screen shapes (fr55 / venu2 / venusq2 / fenix847mm / venux1) + full 80-device package on release | `make build` / `make package` | CI (blocking) |
| On-device pass | Hardware behaviors that cannot be simulated | Real watch | Manual, before each release |

## Running the automated suite

```bash
make sim          # start the simulator once
make test         # build with --unit-test and run on fr55
make test DEVICE=venu2   # same suite on a touch/AMOLED device
```

The suite includes **integration tests that exercise the real platform** in
the simulator VM: Application.Storage round-trips, loading all 34 stretch
drawables, the complete i18n tables for all six languages, and FIT lap-field
name-length constraints.

## Why some things cannot be auto-tested (and what covers them)

| Not automatable | Reason | Covered by |
|---|---|---|
| Background temporal events firing on schedule | Simulator triggers them only manually; timing policy is firmware-side | On-device pass §3 |
| System wake prompt ("open app?") | OS-level dialog, no API | On-device pass §3 |
| Vibration / tones / backlight behavior | Hardware | On-device pass §4, §5 |
| FIT upload & Garmin Connect rendering | Cloud round-trip | On-device pass §6 |
| Touch vs. button input mapping | Simulator input ≠ real digitizer | On-device pass §7 (touch device) |
| `Dc`-dependent drawing (`fitText`, layout) | No graphics context in unit tests | Simulator screenshots during development |

## On-device test pass (run before each release)

Sideload: `make build DEVICE=fr55`, copy `bin/Stretches-fr55.prg` to
`GARMIN/APPS/` over USB. Reset app state by uninstalling first when testing
first-run behavior.

### 1. First run & home
- [ ] Fresh install opens to home with a seeded 6-stretch routine, `--:--`
      next-session time, MENU pill.
- [ ] No schedule is enabled by default (no surprise alarms).

### 2. Menus
- [ ] My stretches opens instantly; toggling flips the sub-label immediately.
- [ ] Durations lists only selected stretches; picker changes persist.
- [ ] Settings: default duration, Sound On/Off, Vibration On/Off, Language.
- [ ] Language switch re-labels visibly (check menu titles + a stretch name);
      persists across app restarts.

### 3. Scheduled reminder (the critical path)
- [ ] Add a time ~7 min ahead, leave it enabled, **exit the app**.
- [ ] Within ~5 min after the set time the watch shows the system prompt.
- [ ] **Accept** → app opens directly on Start / Snooze 15 min / Skip; watch
      vibrates/beeps per settings. No crash.
- [ ] Snooze → prompt returns ~15 min later. Skip → no re-prompt.
- [ ] With the app open on home, the prompt appears within ~5 s of the time.

### 4. Workout flow
- [ ] Start → 5 s countdown → name + 3 s preview → stretch with illustration,
      progress ring, countdown inside the ring; nothing clipped/overlapping.
- [ ] Short vibe between stretches; START pauses/resumes; DOWN skips;
      BACK asks confirmation and resumes on "No".
- [ ] Backlight stays on during the whole workout (or times out gracefully
      per device policy — never crashes).
- [ ] Congratulations screen, then Save/Discard; BACK cannot lose the
      recording silently.

### 5. Sound / vibration settings
- [ ] Sound Off ⇒ no tones anywhere; Vibration Off ⇒ no vibes anywhere.

### 6. Garmin Connect report
- [ ] Saved activity appears as Flexibility Training with duration, heart
      rate and calories.
- [ ] One lap per completed stretch; each lap shows the stretch name and
      hold seconds (custom fields); skipped stretches produce no lap.

### 7. Second device (touch — Venu/Venu Sq family), when available
- [ ] All screens navigable by touch (menus, alert options, pickers, pause).
- [ ] No tones offered/played (device has no beeper) and no crash.

## Bug taxonomy this process guards against

Every on-device bug found so far belonged to one of these classes — each now
has a dedicated guard:

1. **Symbol missing on some device** (CheckboxMenuItem, TONE_*): caught by
   `scripts/audit_api_usage.py` in CI.
2. **UI calls in wrong lifecycle moment** (pushView during cold launch):
   covered by code review rules + the launch-path integration around
   `getInitialView`.
3. **Unhandled platform exceptions** (BacklightOnTooLongException): audit of
   "Throws:" sections + try/catch at every hardware call.
4. **Logic drift**: the Run No Evil suite.
