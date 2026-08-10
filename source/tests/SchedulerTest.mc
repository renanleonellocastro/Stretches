import Toybox.Lang;
import Toybox.Test;
import Toybox.Time;

// Unit tests for the pure scheduling math in Scheduler, plus Storage-backed
// integration tests for the glue functions (real Storage in the simulator).

(:test)
function testDueWhenScheduleFiredSinceLastCheck(logger as Test.Logger) as Boolean {
    // 09:00 alarm; now 09:02 (32520s of day); last check was at 08:58.
    var now = 1000000;
    var nowSec = 9 * 3600 + 2 * 60;
    var schedules = [[9, 0, true]];
    Test.assert(Scheduler.isScheduleDueSince(now - 240, now, nowSec, schedules));
    return true;
}

(:test)
function testNotDueWhenAlreadyCheckedAfterAlarm(logger as Test.Logger) as Boolean {
    // Same 09:00 alarm at 09:02, but we already checked 1 minute ago (09:01).
    var now = 1000000;
    var nowSec = 9 * 3600 + 2 * 60;
    var schedules = [[9, 0, true]];
    Test.assert(!Scheduler.isScheduleDueSince(now - 60, now, nowSec, schedules));
    return true;
}

(:test)
function testNotDueBeforeAlarmTime(logger as Test.Logger) as Boolean {
    // Now 08:59, alarm 09:00 — the last occurrence was yesterday, long ago.
    var now = 1000000;
    var nowSec = 8 * 3600 + 59 * 60;
    var schedules = [[9, 0, true]];
    Test.assert(!Scheduler.isScheduleDueSince(now - 600, now, nowSec, schedules));
    return true;
}

(:test)
function testDueIgnoresDisabledSchedule(logger as Test.Logger) as Boolean {
    var now = 1000000;
    var nowSec = 9 * 3600 + 2 * 60;
    Test.assert(!Scheduler.isScheduleDueSince(now - 240, now, nowSec, [[9, 0, false]]));
    return true;
}

(:test)
function testSecondsToNextPicksEarliestToday(logger as Test.Logger) as Boolean {
    // 08:00:00 now; alarms at 09:30 and 18:00.
    var schedules = [[9, 30, true], [18, 0, true]];
    var delta = Scheduler.secondsToNext(8 * 3600, schedules);
    Test.assertEqual(delta, 1 * 3600 + 30 * 60);
    return true;
}

(:test)
function testSecondsToNextWrapsToTomorrow(logger as Test.Logger) as Boolean {
    // 23:59:00 now; alarm at 00:05 -> 6 minutes away, crossing midnight.
    var schedules = [[0, 5, true]];
    var delta = Scheduler.secondsToNext(23 * 3600 + 59 * 60, schedules);
    Test.assertEqual(delta, 6 * 60);
    return true;
}

(:test)
function testSecondsToNextExactNowGoesToTomorrow(logger as Test.Logger) as Boolean {
    // An alarm exactly now schedules for tomorrow, not immediately again.
    var schedules = [[10, 0, true]];
    var delta = Scheduler.secondsToNext(10 * 3600, schedules);
    Test.assertEqual(delta, 24 * 3600);
    return true;
}

(:test)
function testSecondsToNextIgnoresDisabled(logger as Test.Logger) as Boolean {
    var schedules = [[9, 0, false], [11, 0, true]];
    var delta = Scheduler.secondsToNext(8 * 3600, schedules);
    Test.assertEqual(delta, 3 * 3600);
    return true;
}

(:test)
function testSecondsToNextAllDisabledReturnsNull(logger as Test.Logger) as Boolean {
    var schedules = [[9, 0, false], [11, 0, false]];
    Test.assert(Scheduler.secondsToNext(8 * 3600, schedules) == null);
    return true;
}

(:test)
function testSecondsToNextEmptyReturnsNull(logger as Test.Logger) as Boolean {
    Test.assert(Scheduler.secondsToNext(8 * 3600, []) == null);
    return true;
}

(:test)
function testNextAlarmPrefersSnoozeWhenEarlier(logger as Test.Logger) as Boolean {
    var nowEpoch = 1000000;
    var schedules = [[12, 0, true]];      // 4 hours away from 08:00
    var snooze = nowEpoch + 15 * 60;      // 15 minutes away
    var next = Scheduler.nextAlarmEpoch(nowEpoch, 8 * 3600, schedules, snooze);
    Test.assertEqual(next, snooze);
    return true;
}

(:test)
function testNextAlarmPrefersScheduleWhenEarlier(logger as Test.Logger) as Boolean {
    var nowEpoch = 1000000;
    var schedules = [[8, 5, true]];       // 5 minutes away from 08:00
    var snooze = nowEpoch + 15 * 60;
    var next = Scheduler.nextAlarmEpoch(nowEpoch, 8 * 3600, schedules, snooze);
    Test.assertEqual(next, nowEpoch + 5 * 60);
    return true;
}

(:test)
function testNextAlarmIgnoresExpiredSnooze(logger as Test.Logger) as Boolean {
    var nowEpoch = 1000000;
    var next = Scheduler.nextAlarmEpoch(nowEpoch, 8 * 3600, [], nowEpoch - 10);
    Test.assert(next == null);
    return true;
}

(:test)
function testNextAlarmSnoozeOnly(logger as Test.Logger) as Boolean {
    var nowEpoch = 1000000;
    var next = Scheduler.nextAlarmEpoch(nowEpoch, 8 * 3600, [], nowEpoch + 900);
    Test.assertEqual(next, nowEpoch + 900);
    return true;
}

// --- Additional pure-math cases ------------------------------------------

(:test)
function testDeltaToEntryDisabledReturnsNull(logger as Test.Logger) as Boolean {
    Test.assert(Scheduler.deltaToEntry(8 * 3600, [9, 0, false]) == null);
    return true;
}

(:test)
function testDeltaToEntryExactNowWrapsFullDay(logger as Test.Logger) as Boolean {
    Test.assertEqual(Scheduler.deltaToEntry(10 * 3600, [10, 0, true]), 24 * 3600);
    return true;
}

(:test)
function testDeltaToEntryFutureToday(logger as Test.Logger) as Boolean {
    Test.assertEqual(Scheduler.deltaToEntry(8 * 3600, [9, 15, true]),
                     1 * 3600 + 15 * 60);
    return true;
}

(:test)
function testEntrySecondOfDay(logger as Test.Logger) as Boolean {
    Test.assertEqual(Scheduler.entrySecondOfDay([0, 0, true]), 0);
    Test.assertEqual(Scheduler.entrySecondOfDay([23, 59, true]), 23 * 3600 + 59 * 60);
    return true;
}

(:test)
function testNextAlarmPicksMinOfMultipleSchedules(logger as Test.Logger) as Boolean {
    var nowEpoch = 1000000;
    var schedules = [[18, 0, true], [9, 30, true], [12, 0, true]];
    var next = Scheduler.nextAlarmEpoch(nowEpoch, 8 * 3600, schedules, null);
    Test.assertEqual(next, nowEpoch + 1 * 3600 + 30 * 60);
    return true;
}

(:test)
function testDueBoundaryExactlyAtLastCheckIsNotDue(logger as Test.Logger) as Boolean {
    // The alarm occurrence falls exactly ON the last-check watermark; the
    // window is (lastEpoch, nowEpoch], so it must NOT re-fire (strict >).
    var now = 1000000;
    var nowSec = 9 * 3600 + 5 * 60;   // 09:05:00; alarm 09:00 = 300s ago
    Test.assert(!Scheduler.isScheduleDueSince(now - 300, now, nowSec, [[9, 0, true]]));
    return true;
}

(:test)
function testDueExactlyAtNowEpoch(logger as Test.Logger) as Boolean {
    // The alarm comes due at this very second: secsAgo == 0, due.
    var now = 1000000;
    var nowSec = 9 * 3600;
    Test.assert(Scheduler.isScheduleDueSince(now - 60, now, nowSec, [[9, 0, true]]));
    return true;
}

(:test)
function testDueWhenOnlyOneOfManyEntriesFired(logger as Test.Logger) as Boolean {
    var now = 1000000;
    var nowSec = 9 * 3600 + 2 * 60;
    // 07:00 fired long before the watermark, 12:00 not yet, 09:00 just did.
    var schedules = [[7, 0, true], [12, 0, true], [9, 0, true]];
    Test.assert(Scheduler.isScheduleDueSince(now - 240, now, nowSec, schedules));
    // Without the 09:00 entry nothing is due.
    Test.assert(!Scheduler.isScheduleDueSince(now - 240, now, nowSec,
                                              [[7, 0, true], [12, 0, true]]));
    return true;
}

(:test)
function testDueAcrossMidnightWraparound(logger as Test.Logger) as Boolean {
    // Alarm 23:58, now 00:03; last check 6 minutes ago (before midnight).
    var now = 1000000;
    var nowSec = 3 * 60;
    Test.assert(Scheduler.isScheduleDueSince(now - 360, now, nowSec, [[23, 58, true]]));
    // Already checked 2 minutes ago (00:01, after the alarm): not due.
    Test.assert(!Scheduler.isScheduleDueSince(now - 120, now, nowSec, [[23, 58, true]]));
    return true;
}

// --- Storage-backed integration (real Storage in the simulator) ----------

(:test)
function testSnoozeDueSinceFiredClearsAndReturnsTrue(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSnoozeUntil(now - 10);
        Test.assert(Scheduler.snoozeDueSince(now - 100, now));
        Test.assert(Prefs.getSnoozeUntil() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testSnoozeDueSinceFutureKeepsSnooze(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSnoozeUntil(now + 600);
        Test.assert(!Scheduler.snoozeDueSince(now - 100, now));
        Test.assertEqual(Prefs.getSnoozeUntil(), now + 600);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testSnoozeDueSinceFiredBeforeWatermarkClearsButFalse(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        // Snooze expired before the last check: stale, clear without firing.
        var now = 5000000;
        Prefs.setSnoozeUntil(now - 100);
        Test.assert(!Scheduler.snoozeDueSince(now - 50, now));
        Test.assert(Prefs.getSnoozeUntil() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testActiveSnoozeExpiredClearsAndReturnsNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSnoozeUntil(now - 1);
        Test.assert(Scheduler.activeSnooze(now) == null);
        Test.assert(Prefs.getSnoozeUntil() == null);
        Prefs.setSnoozeUntil(now + 300);
        Test.assertEqual(Scheduler.activeSnooze(now), now + 300);
        Test.assertEqual(Prefs.getSnoozeUntil(), now + 300);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasActiveAlarmsWithEnabledSchedule(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSchedules([[9, 0, true]]);
        Prefs.setSnoozeUntil(null);
        Test.assert(Scheduler.hasActiveAlarms(now));
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasActiveAlarmsWithFutureSnoozeOnly(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSchedules([[9, 0, false]]);
        Prefs.setSnoozeUntil(now + 60);
        Test.assert(Scheduler.hasActiveAlarms(now));
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testHasActiveAlarmsFalseWhenNothingActive(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var now = 5000000;
        Prefs.setSchedules([[9, 0, false]]);
        Prefs.setSnoozeUntil(now - 60);   // expired snooze does not count
        Test.assert(!Scheduler.hasActiveAlarms(now));
        Prefs.setSchedules([]);
        Prefs.setSnoozeUntil(null);
        Test.assert(!Scheduler.hasActiveAlarms(now));
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testBackgroundCheckDueAndAdvancesWatermark(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        var nowSec = Scheduler.nowSecOfDay();
        // Plant an enabled schedule that came due ~2 minutes ago (wrapping
        // across midnight when the test happens to run just after 00:00).
        var alarmSec = (((nowSec - 120 + Scheduler.SECS_PER_DAY)
                         % Scheduler.SECS_PER_DAY) / 60) * 60;
        Prefs.setSchedules([[alarmSec / 3600, (alarmSec % 3600) / 60, true]]);
        Prefs.setSnoozeUntil(null);
        Prefs.setLastCheck(nowEpoch - 600);
        Test.assert(Scheduler.backgroundCheck());
        var watermark = Prefs.getLastCheck();
        Test.assert(watermark != null);
        Test.assert((watermark as Lang.Number) >= nowEpoch);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testBackgroundCheckNotDueWhenRecentlyChecked(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        var nowSec = Scheduler.nowSecOfDay();
        var alarmSec = (((nowSec - 120 + Scheduler.SECS_PER_DAY)
                         % Scheduler.SECS_PER_DAY) / 60) * 60;
        Prefs.setSchedules([[alarmSec / 3600, (alarmSec % 3600) / 60, true]]);
        Prefs.setSnoozeUntil(null);
        // Already checked AFTER the alarm fired: must not re-fire.
        Prefs.setLastCheck(nowEpoch - 5);
        Test.assert(!Scheduler.backgroundCheck());
        var watermark = Prefs.getLastCheck();
        Test.assert(watermark != null && (watermark as Lang.Number) >= nowEpoch);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testBackgroundCheckSnoozeFiresAndClears(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        Prefs.setSchedules([]);
        Prefs.setSnoozeUntil(nowEpoch);        // came due right now
        Prefs.setLastCheck(nowEpoch - 300);
        Test.assert(Scheduler.backgroundCheck());
        Test.assert(Prefs.getSnoozeUntil() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRegisterNextCachesEpochAndSetsWatermark(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        Prefs.setSchedules([[9, 0, true]]);
        Prefs.setSnoozeUntil(null);
        Prefs.setLastCheck(null);
        Scheduler.registerNext();
        var next = Prefs.getNextAlarmEpoch();
        Test.assert(next != null);
        Test.assert((next as Lang.Number) > nowEpoch);
        Test.assert((next as Lang.Number) <= nowEpoch + Scheduler.SECS_PER_DAY + 60);
        // First registration starts the check watermark.
        Test.assert(Prefs.getLastCheck() != null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRegisterNextWithoutAlarmsClearsState(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setSchedules([[9, 0, false]]);
        Prefs.setSnoozeUntil(null);
        Prefs.setLastCheck(12345);
        Scheduler.registerNext();
        Test.assert(Prefs.getNextAlarmEpoch() == null);
        Test.assert(Prefs.getLastCheck() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testSchedulerSnoozeSetsFifteenMinutes(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        Prefs.setSchedules([]);
        Prefs.setPendingAlertTs(nowEpoch);
        Scheduler.snooze();
        Test.assert(Prefs.getPendingAlertTs() == null);
        var snooze = Prefs.getSnoozeUntil();
        Test.assert(snooze != null);
        var delta = (snooze as Lang.Number) - nowEpoch;
        Test.assert(delta >= Prefs.SNOOZE_SECS && delta <= Prefs.SNOOZE_SECS + 5);
        // With no schedules the cached next alarm IS the snooze.
        Test.assertEqual(Prefs.getNextAlarmEpoch(), snooze);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testConsumeAlarmClearsPendingStateAndReRegisters(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var nowEpoch = Time.now().value();
        Prefs.setSchedules([]);
        Prefs.setSnoozeUntil(nowEpoch + 600);
        Prefs.setPendingAlertTs(nowEpoch);
        Scheduler.consumeAlarm();
        Test.assert(Prefs.getSnoozeUntil() == null);
        Test.assert(Prefs.getPendingAlertTs() == null);
        Test.assert(Prefs.getNextAlarmEpoch() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
