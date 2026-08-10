import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Alarm scheduling. The pure helpers (secondsToNext / nextAlarmEpoch) are
// deterministic and unit-tested; registerNext() glues them to Storage and
// the Background temporal-event API. Runs in both app and service contexts.
(:background)
module Scheduler {
    const SECS_PER_DAY = 86400;
    // Temporal events cannot fire more often than every 5 minutes; clamp
    // with a safety margin so registration never throws.
    const MIN_LEAD_SECS = 5 * 60 + 30;

    // Seconds from nowSecOfDay (0..86399) until the next enabled schedule
    // entry, looking at today first and wrapping to tomorrow. Returns null
    // when no entry is enabled.
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

    // Seconds from nowSecOfDay until an enabled schedule entry fires (today
    // or wrapped to tomorrow). Null when the entry is disabled.
    function deltaToEntry(nowSecOfDay as Number, entry as Array) as Number? {
        if (!(entry[2] as Boolean)) {
            return null;
        }
        var target = (entry[0] as Number) * 3600 + (entry[1] as Number) * 60;
        var delta = target - nowSecOfDay;
        if (delta <= 0) {
            delta += SECS_PER_DAY;
        }
        return delta;
    }

    // Epoch seconds of the next alarm: the earlier of the next schedule
    // occurrence and a pending snooze. Returns null when nothing is due.
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

    // Recompute the next alarm from Storage and (re)register the temporal
    // event. Also caches the alarm epoch so the foreground app can poll it.
    function registerNext() as Void {
        var nowEpoch = Time.now().value();
        var snooze = activeSnooze(nowEpoch);
        var next = nextAlarmEpoch(nowEpoch, nowSecOfDay(), Prefs.getSchedules(), snooze);
        Prefs.setNextAlarmEpoch(next);
        if (next == null) {
            Background.deleteTemporalEvent();
            return;
        }
        scheduleTemporalEvent(next as Number, nowEpoch);
    }

    function nowSecOfDay() as Number {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (info.hour as Number) * 3600 + (info.min as Number) * 60 + (info.sec as Number);
    }

    function activeSnooze(nowEpoch as Number) as Number? {
        var snooze = Prefs.getSnoozeUntil();
        if (snooze != null && (snooze as Number) <= nowEpoch) {
            // Expired snooze: it either fired or was missed; drop it.
            Prefs.setSnoozeUntil(null);
            return null;
        }
        return snooze;
    }

    function scheduleTemporalEvent(next as Number, nowEpoch as Number) as Void {
        var eventEpoch = next;
        if (eventEpoch < nowEpoch + MIN_LEAD_SECS) {
            // The foreground poller covers alarms due sooner than the
            // background API allows.
            eventEpoch = nowEpoch + MIN_LEAD_SECS;
        }
        try {
            Background.registerForTemporalEvent(new Time.Moment(eventEpoch));
        } catch (e) {
            try {
                Background.registerForTemporalEvent(new Time.Moment(nowEpoch + 2 * MIN_LEAD_SECS));
            } catch (e2) {
                // Give up silently; next app launch re-registers.
            }
        }
    }

    // Marks the alarm as fired and prepares the following one.
    function consumeAlarm() as Void {
        Prefs.setSnoozeUntil(null);
        Prefs.setPendingAlertTs(null);
        registerNext();
    }

    // Snooze the current alarm by SNOOZE_SECS.
    function snooze() as Void {
        Prefs.setPendingAlertTs(null);
        Prefs.setSnoozeUntil(Time.now().value() + Prefs.SNOOZE_SECS);
        registerNext();
    }
}
