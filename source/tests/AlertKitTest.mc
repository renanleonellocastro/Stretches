import Toybox.Attention;
import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

// Integration tests for AlertKit's gating logic over real Storage. The
// audible/haptic side effects (alarm()/vibrate()) are intentionally not
// invoked; the gating is what matters and keeps the suite quiet.

(:test)
function testHasPendingAlertFalseWhenNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setPendingAlertTs(null);
        Test.assert(!AlertKit.hasPendingAlert());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasPendingAlertTrueWhenFresh(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setPendingAlertTs(Time.now().value());
        Test.assert(AlertKit.hasPendingAlert());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasPendingAlertFalseWhenOlderThanTtl(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = Time.now().value();
        Prefs.setPendingAlertTs(now - Prefs.PENDING_ALERT_TTL_SECS - 1);
        Test.assert(!AlertKit.hasPendingAlert());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasPendingAlertFalseForFutureTimestamp(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        // A timestamp from the future (clock skew) must not count as pending.
        Prefs.setPendingAlertTs(Time.now().value() + 3600);
        Test.assert(!AlertKit.hasPendingAlert());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testNextAlarmReachedTrueFalseAndNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = Time.now().value();
        Prefs.setNextAlarmEpoch(null);
        Test.assert(!AlertKit.nextAlarmReached());
        Prefs.setNextAlarmEpoch(now + 300);
        Test.assert(!AlertKit.nextAlarmReached());
        Prefs.setNextAlarmEpoch(now - 1);
        Test.assert(AlertKit.nextAlarmReached());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testCheckForegroundDueFalseWhenNotReached(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = Time.now().value();
        Prefs.setNextAlarmEpoch(now + 300);
        Prefs.setPendingAlertTs(null);
        Test.assert(!AlertKit.checkForegroundDue());
        Test.assert(Prefs.getPendingAlertTs() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testCheckForegroundDueFlagsPendingAndReRegisters(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = Time.now().value();
        // The cached alarm time was reached; a stale snooze is also expired
        // and an enabled schedule exists to be re-registered.
        Prefs.setSchedules([[9, 0, true]]);
        Prefs.setNextAlarmEpoch(now - 5);
        Prefs.setSnoozeUntil(now - 10);
        Prefs.setPendingAlertTs(null);
        Test.assert(AlertKit.checkForegroundDue());
        var pending = Prefs.getPendingAlertTs();
        Test.assert(pending != null);
        Test.assert((pending as Lang.Number) >= now);
        // Expired snooze cleared, next alarm recomputed into the future.
        Test.assert(Prefs.getSnoozeUntil() == null);
        var next = Prefs.getNextAlarmEpoch();
        Test.assert(next != null);
        Test.assert((next as Lang.Number) > now);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testClearExpiredSnoozeOnlyClearsExpired(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = Time.now().value();
        Prefs.setSnoozeUntil(now - 1);
        AlertKit.clearExpiredSnooze(now);
        Test.assert(Prefs.getSnoozeUntil() == null);
        Prefs.setSnoozeUntil(now + 60);
        AlertKit.clearExpiredSnooze(now);
        Test.assertEqual(Prefs.getSnoozeUntil(), now + 60);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testCanToneRespectsTonePref(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setToneOn(false);
        Test.assert(!AlertKit.canTone());
        Prefs.setToneOn(true);
        // With the pref on, availability is exactly the device capability.
        Test.assertEqual(AlertKit.canTone(), (Attention has :playTone));
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
