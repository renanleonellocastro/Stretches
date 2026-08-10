import Toybox.Application;
import Toybox.Lang;

// Persistent state. Everything lives in Application.Storage so both the
// foreground app and the background service (API >= 3.2) share one source
// of truth.
(:background)
module Prefs {
    const KEY_SCHEDULES = "schedules";              // Array of [hour, minute, enabled]
    const KEY_ROUTINE = "routine";                  // Array of stretch id Strings
    const KEY_DURATIONS = "durations";              // Dictionary stretch id -> seconds
    const KEY_DEFAULT_DURATION = "defaultDuration"; // Number, seconds
    const KEY_TONE = "toneOn";                      // Boolean
    const KEY_VIBE = "vibeOn";                      // Boolean
    const KEY_SNOOZE_UNTIL = "snoozeUntil";         // Number, epoch seconds
    const KEY_PENDING_ALERT = "pendingAlertTs";     // Number, epoch seconds
    const KEY_NEXT_ALARM = "nextAlarmEpoch";        // Number, epoch seconds
    const KEY_LAST_CHECK = "lastCheckEpoch";        // Number, epoch of last poll
    const KEY_SEEDED = "seeded";                     // Boolean, first-run flag
    const KEY_LANGUAGE = "language";                 // String code, or null = follow system

    const DEFAULT_DURATION_SECS = 30;
    const SNOOZE_SECS = 15 * 60;
    const PENDING_ALERT_TTL_SECS = 30 * 60;

    function getSchedules() as Array {
        var v = Application.Storage.getValue(KEY_SCHEDULES);
        return v == null ? [] : v as Array;
    }

    function setSchedules(schedules as Array) as Void {
        Application.Storage.setValue(KEY_SCHEDULES, schedules);
    }

    function getRoutine() as Array {
        var v = Application.Storage.getValue(KEY_ROUTINE);
        return v == null ? [] : v as Array;
    }

    function setRoutine(ids as Array) as Void {
        Application.Storage.setValue(KEY_ROUTINE, ids);
    }

    function getDurations() as Dictionary {
        var v = Application.Storage.getValue(KEY_DURATIONS);
        return v == null ? {} : v as Dictionary;
    }

    function setDuration(stretchId as String, seconds as Number) as Void {
        var d = getDurations();
        d.put(stretchId, seconds);
        Application.Storage.setValue(KEY_DURATIONS, d);
    }

    function getDefaultDuration() as Number {
        var v = Application.Storage.getValue(KEY_DEFAULT_DURATION);
        return v == null ? DEFAULT_DURATION_SECS : v as Number;
    }

    function setDefaultDuration(seconds as Number) as Void {
        Application.Storage.setValue(KEY_DEFAULT_DURATION, seconds);
    }

    function isToneOn() as Boolean {
        var v = Application.Storage.getValue(KEY_TONE);
        return v == null ? true : v as Boolean;
    }

    function setToneOn(on as Boolean) as Void {
        Application.Storage.setValue(KEY_TONE, on);
    }

    function isVibeOn() as Boolean {
        var v = Application.Storage.getValue(KEY_VIBE);
        return v == null ? true : v as Boolean;
    }

    function setVibeOn(on as Boolean) as Void {
        Application.Storage.setValue(KEY_VIBE, on);
    }

    function getSnoozeUntil() as Number? {
        return Application.Storage.getValue(KEY_SNOOZE_UNTIL) as Number?;
    }

    function setSnoozeUntil(epoch as Number?) as Void {
        Application.Storage.setValue(KEY_SNOOZE_UNTIL, epoch);
    }

    function getPendingAlertTs() as Number? {
        return Application.Storage.getValue(KEY_PENDING_ALERT) as Number?;
    }

    function setPendingAlertTs(epoch as Number?) as Void {
        Application.Storage.setValue(KEY_PENDING_ALERT, epoch);
    }

    // On first launch, give the user a ready-to-use starter routine so the
    // app is useful immediately (no schedule is enabled — no surprise
    // alarms). Idempotent: runs at most once per install.
    function seedDefaultsIfNeeded() as Void {
        if (Application.Storage.getValue(KEY_SEEDED) != null) {
            return;
        }
        Application.Storage.setValue(KEY_SEEDED, true);
        if (getRoutine().size() == 0) {
            setRoutine([
                "neck_tilt_right", "neck_tilt_left",
                "shoulder_cross_right", "shoulder_cross_left",
                "side_bend_right", "side_bend_left"
            ]);
        }
    }

    function getNextAlarmEpoch() as Number? {
        return Application.Storage.getValue(KEY_NEXT_ALARM) as Number?;
    }

    function setNextAlarmEpoch(epoch as Number?) as Void {
        Application.Storage.setValue(KEY_NEXT_ALARM, epoch);
    }

    function getLastCheck() as Number? {
        return Application.Storage.getValue(KEY_LAST_CHECK) as Number?;
    }

    function setLastCheck(epoch as Number?) as Void {
        Application.Storage.setValue(KEY_LAST_CHECK, epoch);
    }

    // Runtime UI language. null means "follow the device system locale".
    function getLanguage() as Lang.String? {
        return Application.Storage.getValue(KEY_LANGUAGE) as Lang.String?;
    }

    function setLanguage(code as Lang.String?) as Void {
        Application.Storage.setValue(KEY_LANGUAGE, code);
    }
}
