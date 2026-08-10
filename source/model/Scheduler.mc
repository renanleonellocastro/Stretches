import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Alarm scheduling. The pure helpers are deterministic and unit-tested;
// registerNext()/backgroundCheck() glue them to Storage and the Background
// temporal-event API. Runs in both the app and the background service.
//
// Reminders use a repeating 5-minute temporal event (the finest the platform
// allows) rather than a one-shot: on each wake the service checks whether any
// enabled time has passed since the previous check, which is self-healing and
// survives the app being closed. Alarms therefore fire within ~5 minutes of
// the set time.
(:background)
module Scheduler {
    const SECS_PER_DAY = 86400;
    const POLL_SECS = 300;   // 5 min — the minimum temporal-event interval

    // --- Pure helpers (unit-tested) --------------------------------------

    // Seconds from nowSecOfDay until the next enabled entry (today, wrapping
    // to tomorrow). Null when nothing is enabled.
    function secondsToNext(nowSecOfDay as Number, schedules as Array) as Number? {
        var best = null;
        for (var i = 0; i < schedules.size(); i++) {
            var delta = deltaToEntry(nowSecOfDay, schedules[i] as Array);
            if (delta != null && (best == null || (delta as Number) < (best as Number))) {
                best = delta;
            }
        }
        return best;
    }

    function deltaToEntry(nowSecOfDay as Number, entry as Array) as Number? {
        if (!(entry[2] as Boolean)) {
            return null;
        }
        var delta = entrySecondOfDay(entry) - nowSecOfDay;
        if (delta <= 0) {
            delta += SECS_PER_DAY;
        }
        return delta;
    }

    function entrySecondOfDay(entry as Array) as Number {
        return (entry[0] as Number) * 3600 + (entry[1] as Number) * 60;
    }

    // Epoch of the next future alarm (schedule or snooze), for display.
    function nextAlarmEpoch(nowEpoch as Number, nowSecOfDay as Number,
                            schedules as Array, snoozeUntil as Number?) as Number? {
        var next = null;
        var delta = secondsToNext(nowSecOfDay, schedules);
        if (delta != null) {
            next = nowEpoch + (delta as Number);
        }
        if (snoozeUntil != null && (snoozeUntil as Number) > nowEpoch) {
            if (next == null || (snoozeUntil as Number) < (next as Number)) {
                next = snoozeUntil;
            }
        }
        return next;
    }

    // True when any enabled schedule's most recent occurrence falls in the
    // (lastEpoch, nowEpoch] window — i.e. it came due since the last check.
    function isScheduleDueSince(lastEpoch as Number, nowEpoch as Number,
                                nowSecOfDay as Number, schedules as Array) as Boolean {
        for (var i = 0; i < schedules.size(); i++) {
            var entry = schedules[i] as Array;
            if (!(entry[2] as Boolean)) {
                continue;
            }
            var secsAgo = ((nowSecOfDay - entrySecondOfDay(entry)) % SECS_PER_DAY
                           + SECS_PER_DAY) % SECS_PER_DAY;
            if (nowEpoch - secsAgo > lastEpoch) {
                return true;
            }
        }
        return false;
    }

    // --- Storage / platform glue -----------------------------------------

    function nowSecOfDay() as Number {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (info.hour as Number) * 3600 + (info.min as Number) * 60 + (info.sec as Number);
    }

    function hasActiveAlarms(nowEpoch as Number) as Boolean {
        var schedules = Prefs.getSchedules();
        for (var i = 0; i < schedules.size(); i++) {
            if ((schedules[i] as Array)[2] as Boolean) {
                return true;
            }
        }
        var snooze = Prefs.getSnoozeUntil();
        return snooze != null && (snooze as Number) > nowEpoch;
    }

    function activeSnooze(nowEpoch as Number) as Number? {
        var snooze = Prefs.getSnoozeUntil();
        if (snooze != null && (snooze as Number) <= nowEpoch) {
            Prefs.setSnoozeUntil(null);   // expired: fired or missed
            return null;
        }
        return snooze;
    }

    // Refresh the cached next-alarm time and keep the 5-minute poll running
    // while (and only while) something is scheduled.
    function registerNext() as Void {
        var now = Time.now().value();
        Prefs.setNextAlarmEpoch(
            nextAlarmEpoch(now, nowSecOfDay(), Prefs.getSchedules(), activeSnooze(now)));
        if (hasActiveAlarms(now)) {
            if (Prefs.getLastCheck() == null) {
                Prefs.setLastCheck(now);
            }
            registerPoll();
        } else {
            Background.deleteTemporalEvent();
            Prefs.setLastCheck(null);
        }
    }

    function registerPoll() as Void {
        try {
            Background.registerForTemporalEvent(new Time.Duration(POLL_SECS));
        } catch (e) {
            // Re-registered on the next app launch or schedule change.
        }
    }

    // Called from the background service: has an alarm come due since the
    // previous wake? Advances the check watermark and clears a fired snooze.
    function backgroundCheck() as Boolean {
        var now = Time.now().value();
        var last = Prefs.getLastCheck();
        if (last == null) {
            last = now - 1;
        }
        var due = isScheduleDueSince(last as Number, now, nowSecOfDay(), Prefs.getSchedules())
                  || snoozeDueSince(last as Number, now);
        Prefs.setLastCheck(now);
        return due;
    }

    function snoozeDueSince(lastEpoch as Number, nowEpoch as Number) as Boolean {
        var snooze = Prefs.getSnoozeUntil();
        if (snooze == null || (snooze as Number) > nowEpoch) {
            return false;
        }
        Prefs.setSnoozeUntil(null);
        return (snooze as Number) > lastEpoch;
    }

    // The user answered the prompt: clear pending state and line up the next.
    function consumeAlarm() as Void {
        Prefs.setSnoozeUntil(null);
        Prefs.setPendingAlertTs(null);
        registerNext();
    }

    function snooze() as Void {
        Prefs.setPendingAlertTs(null);
        Prefs.setSnoozeUntil(Time.now().value() + Prefs.SNOOZE_SECS);
        registerNext();
    }
}
