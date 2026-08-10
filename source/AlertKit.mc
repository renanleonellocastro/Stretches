import Toybox.Attention;
import Toybox.Lang;
import Toybox.Time;

// Foreground attention helpers (vibration + tones), honoring user settings.
module AlertKit {
    function alarm() as Void {
        vibrate([new Attention.VibeProfile(100, 1200), new Attention.VibeProfile(0, 300),
                 new Attention.VibeProfile(100, 1200)]);
        tone(Attention.TONE_ALARM);
    }

    function stretchDone() as Void {
        vibrate([new Attention.VibeProfile(80, 300)]);
        tone(Attention.TONE_KEY);
    }

    function workoutDone() as Void {
        vibrate([new Attention.VibeProfile(100, 500), new Attention.VibeProfile(0, 200),
                 new Attention.VibeProfile(100, 700)]);
        tone(Attention.TONE_SUCCESS);
    }

    function vibrate(profile as Array) as Void {
        if (!Prefs.isVibeOn()) {
            return;
        }
        if (Attention has :vibrate) {
            Attention.vibrate(profile as Array<Attention.VibeProfile>);
        }
    }

    function tone(toneId as Attention.Tone) as Void {
        if (!Prefs.isToneOn()) {
            return;
        }
        if (Attention has :playTone) {
            Attention.playTone(toneId);
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
