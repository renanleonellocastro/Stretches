import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Integration tests for RoutineModel over the real Storage-backed Prefs.

(:test)
function testRoutineToggleAndIsSelectedRoundTrip(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setRoutine([]);
        Test.assert(!RoutineModel.isSelected("quad_left"));
        RoutineModel.toggle("quad_left");
        Test.assert(RoutineModel.isSelected("quad_left"));
        RoutineModel.toggle("quad_left");
        Test.assert(!RoutineModel.isSelected("quad_left"));
        Test.assertEqual(RoutineModel.selectedIds().size(), 0);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineToggleKeepsOthersInOrder(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setRoutine(["a", "b", "c"]);
        RoutineModel.toggle("b");                 // remove middle
        var ids = RoutineModel.selectedIds();
        Test.assertEqual(ids.size(), 2);
        Test.assertEqual(ids[0], "a");
        Test.assertEqual(ids[1], "c");
        RoutineModel.toggle("d");                 // append new
        ids = RoutineModel.selectedIds();
        Test.assertEqual(ids.size(), 3);
        Test.assertEqual(ids[2], "d");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineMoveUpDown(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setRoutine(["a", "b", "c"]);
        RoutineModel.moveDown("a");                // a,b,c -> b,a,c
        var ids = RoutineModel.selectedIds();
        Test.assertEqual(ids[0], "b");
        Test.assertEqual(ids[1], "a");
        Test.assertEqual(ids[2], "c");
        RoutineModel.moveUp("c");                   // b,a,c -> b,c,a
        ids = RoutineModel.selectedIds();
        Test.assertEqual(ids[1], "c");
        Test.assertEqual(ids[2], "a");
        // Edges are no-ops.
        RoutineModel.moveUp("b");                   // already first
        RoutineModel.moveDown("a");                 // already last
        ids = RoutineModel.selectedIds();
        Test.assertEqual(ids[0], "b");
        Test.assertEqual(ids[2], "a");
        // Unknown id is a no-op.
        RoutineModel.moveUp("zzz");
        Test.assertEqual(RoutineModel.selectedIds().size(), 3);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineSetSelectedIsIdempotent(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setRoutine([]);
        RoutineModel.setSelected("calf_left", true);
        RoutineModel.setSelected("calf_left", true);   // no duplicate
        Test.assertEqual(RoutineModel.selectedIds().size(), 1);
        Test.assert(RoutineModel.isSelected("calf_left"));
        RoutineModel.setSelected("calf_left", false);
        RoutineModel.setSelected("calf_left", false);  // no error / re-add
        Test.assertEqual(RoutineModel.selectedIds().size(), 0);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineDurationForDefaultVsExplicit(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_DURATIONS);
        Prefs.setDefaultDuration(45);
        Test.assertEqual(RoutineModel.durationFor("quad_left"), 45);
        Prefs.setDuration("quad_left", 20);
        Test.assertEqual(RoutineModel.durationFor("quad_left"), 20);
        Test.assertEqual(RoutineModel.durationFor("quad_right"), 45);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineEstimatedTotalSecs(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Application.Storage.deleteValue(Prefs.KEY_DURATIONS);
        Prefs.setDefaultDuration(30);
        Prefs.setRoutine(["a", "b"]);
        Prefs.setDuration("a", 10);
        // PREP + (ANNOUNCE + 10) + (ANNOUNCE + 30 default)
        var expected = WORKOUT_PREP_SECS
                       + (WORKOUT_ANNOUNCE_SECS + 10)
                       + (WORKOUT_ANNOUNCE_SECS + 30);
        Test.assertEqual(RoutineModel.estimatedTotalSecs(), expected);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testRoutineEstimatedTotalSecsEmptyRoutine(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setRoutine([]);
        Test.assertEqual(RoutineModel.estimatedTotalSecs(), WORKOUT_PREP_SECS);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
