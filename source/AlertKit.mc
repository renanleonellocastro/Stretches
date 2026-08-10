import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;

// Foreground attention helpers (vibration + tones), honoring user settings.
//
// IMPORTANT: Attention.TONE_* constants do not exist on beeper-less devices
// (the Venu / Venu Sq / Vívoactive families) — evaluating one there throws
// Symbol Not Found at runtime. Every TONE_* reference must therefore sit
// inside an `Attention has :playTone` guard, which is why the tone helpers
// below take no tone argument from callers.
module AlertKit {
    function alarm() as Void {
        vibrate([new Attention.VibeProfile(100, 1200), new Attention.VibeProfile(0, 300),
                 new Attention.VibeProfile(100, 1200)]);
        if (canTone()) {
            Attention.playTone(Attention.TONE_ALARM);
        }
    }

    function startTone() as Void {
        if (canTone()) {
            Attention.playTone(Attention.TONE_START);
        }
    }

    function stretchDone() as Void {
        vibrate([new Attention.VibeProfile(80, 300)]);
        if (canTone()) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }

    function workoutDone() as Void {
        vibrate([new Attention.VibeProfile(100, 500), new Attention.VibeProfile(0, 200),
                 new Attention.VibeProfile(100, 700)]);
        if (canTone()) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
    }

    function canTone() as Boolean {
        return Prefs.isToneOn() && (Attention has :playTone);
    }

    function vibrate(profile as Array) as Void {
        if (!Prefs.isVibeOn()) {
            return;
        }
        if (Attention has :vibrate) {
            Attention.vibrate(profile as Array<Attention.VibeProfile>);
        }
    }

    // True when the background service flagged an alarm that the user has
    // not answered yet (and it is still fresh enough to be meaningful).
    function hasPendingAlert() as Boolean {
        var ts = Prefs.getPendingAlertTs();
        if (ts == null) {
            return false;
        }
        var age = Time.now().value() - (ts as Number);
        return age >= 0 && age < Prefs.PENDING_ALERT_TTL_SECS;
    }

    // Foreground poll: fires the alarm flow when the cached next-alarm time
    // has been reached while the app is open. Returns true when due.
    function checkForegroundDue() as Boolean {
        if (!nextAlarmReached()) {
            return false;
        }
        var now = Time.now().value();
        Prefs.setPendingAlertTs(now);
        clearExpiredSnooze(now);
        Scheduler.registerNext();
        return true;
    }

    function nextAlarmReached() as Boolean {
        var next = Prefs.getNextAlarmEpoch();
        return next != null && Time.now().value() >= (next as Number);
    }

    function clearExpiredSnooze(now as Number) as Void {
        var snooze = Prefs.getSnoozeUntil();
        if (snooze != null && (snooze as Number) <= now) {
            Prefs.setSnoozeUntil(null);
        }
    }
}
