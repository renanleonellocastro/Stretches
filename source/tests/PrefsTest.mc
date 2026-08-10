import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Integration tests for Prefs against the simulator's real Storage.
// Every test snapshots/restores the keys it touches (see TestSupport.mc).

(:test)
function testPrefsSchedulesDefaultEmptyAndRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_SCHEDULES);
        Test.assertEqual(Prefs.getSchedules().size(), 0);
        Prefs.setSchedules([[9, 30, true], [18, 0, false]]);
        var back = Prefs.getSchedules();
        Test.assertEqual(back.size(), 2);
        var first = back[0] as Array;
        Test.assertEqual(first[0], 9);
        Test.assertEqual(first[1], 30);
        Test.assertEqual(first[2], true);
        var second = back[1] as Array;
        Test.assertEqual(second[2], false);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsRoutineDefaultEmptyAndRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_ROUTINE);
        Test.assertEqual(Prefs.getRoutine().size(), 0);
        Prefs.setRoutine(["quad_left", "calf_right"]);
        var back = Prefs.getRoutine();
        Test.assertEqual(back.size(), 2);
        Test.assertEqual(back[0], "quad_left");
        Test.assertEqual(back[1], "calf_right");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsDurationsDefaultEmptyAndSetMerges(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_DURATIONS);
        Test.assertEqual(Prefs.getDurations().size(), 0);
        Prefs.setDuration("quad_left", 45);
        Prefs.setDuration("calf_right", 20);
        // setDuration must merge into the stored dict, not replace it.
        var d = Prefs.getDurations();
        Test.assertEqual(d.size(), 2);
        Test.assertEqual(d.get("quad_left"), 45);
        Test.assertEqual(d.get("calf_right"), 20);
        // Overwriting one id keeps the other.
        Prefs.setDuration("quad_left", 60);
        d = Prefs.getDurations();
        Test.assertEqual(d.get("quad_left"), 60);
        Test.assertEqual(d.get("calf_right"), 20);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsDefaultDurationDefault30AndRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_DEFAULT_DURATION);
        Test.assertEqual(Prefs.getDefaultDuration(), 30);
        Test.assertEqual(Prefs.DEFAULT_DURATION_SECS, 30);
        Prefs.setDefaultDuration(45);
        Test.assertEqual(Prefs.getDefaultDuration(), 45);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsToneDefaultTrueAndRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_TONE);
        Test.assert(Prefs.isToneOn());
        Prefs.setToneOn(false);
        Test.assert(!Prefs.isToneOn());
        Prefs.setToneOn(true);
        Test.assert(Prefs.isToneOn());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsVibeDefaultTrueAndRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_VIBE);
        Test.assert(Prefs.isVibeOn());
        Prefs.setVibeOn(false);
        Test.assert(!Prefs.isVibeOn());
        Prefs.setVibeOn(true);
        Test.assert(Prefs.isVibeOn());
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsSnoozeUntilRoundTripIncludingNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setSnoozeUntil(null);
        Test.assert(Prefs.getSnoozeUntil() == null);
        Prefs.setSnoozeUntil(1234567);
        Test.assertEqual(Prefs.getSnoozeUntil(), 1234567);
        Prefs.setSnoozeUntil(null);
        Test.assert(Prefs.getSnoozeUntil() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsPendingAlertRoundTripIncludingNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setPendingAlertTs(null);
        Test.assert(Prefs.getPendingAlertTs() == null);
        Prefs.setPendingAlertTs(7654321);
        Test.assertEqual(Prefs.getPendingAlertTs(), 7654321);
        Prefs.setPendingAlertTs(null);
        Test.assert(Prefs.getPendingAlertTs() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsNextAlarmAndLastCheckRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setNextAlarmEpoch(null);
        Test.assert(Prefs.getNextAlarmEpoch() == null);
        Prefs.setNextAlarmEpoch(111222);
        Test.assertEqual(Prefs.getNextAlarmEpoch(), 111222);
        Prefs.setLastCheck(null);
        Test.assert(Prefs.getLastCheck() == null);
        Prefs.setLastCheck(333444);
        Test.assertEqual(Prefs.getLastCheck(), 333444);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsSeedDefaultsSeedsSixStretches(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_SEEDED);
        Application.Storage.deleteValue(Prefs.KEY_ROUTINE);
        Prefs.seedDefaultsIfNeeded();
        var routine = Prefs.getRoutine();
        Test.assertEqual(routine.size(), 6);
        // Every seeded id must exist in the catalog.
        for (var i = 0; i < routine.size(); i++) {
            Test.assertMessage(StretchCatalog.find(routine[i] as String) != null,
                               "seeded id not in catalog: " + (routine[i] as String));
        }
        Test.assert(Application.Storage.getValue(Prefs.KEY_SEEDED) != null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsSeedDefaultsIsIdempotent(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_SEEDED);
        Application.Storage.deleteValue(Prefs.KEY_ROUTINE);
        Prefs.seedDefaultsIfNeeded();
        // Simulate the user editing the routine after the first seed.
        Prefs.setRoutine(["quad_left"]);
        Prefs.seedDefaultsIfNeeded();
        var routine = Prefs.getRoutine();
        Test.assertEqual(routine.size(), 1);
        Test.assertEqual(routine[0], "quad_left");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsSeedDefaultsKeepsExistingRoutine(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        // Never seeded, but the user already has a routine (e.g. restored
        // storage): the seeder must not overwrite it.
        Application.Storage.deleteValue(Prefs.KEY_SEEDED);
        Prefs.setRoutine(["calf_left", "calf_right"]);
        Prefs.seedDefaultsIfNeeded();
        var routine = Prefs.getRoutine();
        Test.assertEqual(routine.size(), 2);
        Test.assertEqual(routine[0], "calf_left");
        Test.assert(Application.Storage.getValue(Prefs.KEY_SEEDED) != null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testPrefsLanguageRoundTripIncludingNull(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setLanguage(null);
        Test.assert(Prefs.getLanguage() == null);
        Prefs.setLanguage("por");
        Test.assertEqual(Prefs.getLanguage(), "por");
        Prefs.setLanguage(null);
        Test.assert(Prefs.getLanguage() == null);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
