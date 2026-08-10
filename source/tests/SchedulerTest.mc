import Toybox.Lang;
import Toybox.Test;

// Unit tests for the pure scheduling math in Scheduler.

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
