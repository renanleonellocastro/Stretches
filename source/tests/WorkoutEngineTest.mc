import Toybox.Lang;
import Toybox.Test;

// Unit tests for the workout state machine.

// Test helpers (not annotated with :test so the runner never invokes them).
class SequenceRandom extends RandomSource {
    hidden var _values as Array = [];
    hidden var _i as Number = 0;

    function initialize(values as Array) {
        RandomSource.initialize();
        _values = values;
    }

    function next(bound as Number) as Number {
        var v = (_values[_i % _values.size()] as Number) % bound;
        _i++;
        return v;
    }
}

function makeEngine(ids as Array, durations as Dictionary) as WorkoutEngine {
    return new WorkoutEngine(ids, durations, 30, new SequenceRandom([0]));
}

(:test)
function testShuffleIsPermutation(logger as Test.Logger) as Boolean {
    var ids = ["a", "b", "c", "d"];
    var shuffled = WorkoutEngine.shuffle(ids, new SequenceRandom([1, 0, 1]));
    Test.assertEqual(shuffled.size(), 4);
    for (var i = 0; i < ids.size(); i++) {
        var found = false;
        for (var j = 0; j < shuffled.size(); j++) {
            if ((shuffled[j] as String).equals(ids[i])) {
                found = true;
            }
        }
        Test.assertMessage(found, "missing element after shuffle");
    }
    // Input untouched.
    Test.assertEqual(ids[0], "a");
    return true;
}

(:test)
function testPrepCountdownThenAnnounce(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 2});
    Test.assertEqual(engine.state, STATE_PREP);
    Test.assertEqual(engine.remaining(), 5);
    for (var i = 0; i < 4; i++) {
        Test.assertEqual(engine.tick(), EVENT_TICK);
    }
    Test.assertEqual(engine.tick(), EVENT_WORKOUT_STARTED);
    Test.assertEqual(engine.state, STATE_ANNOUNCE);
    Test.assertEqual(engine.remaining(), 3);
    return true;
}

(:test)
function testFullSingleStretchFlow(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 2});
    for (var i = 0; i < 5; i++) { engine.tick(); }      // prep
    engine.tick();                                       // announce 3 -> 2
    engine.tick();                                       // announce 2 -> 1
    Test.assertEqual(engine.tick(), EVENT_STRETCH_STARTED);
    Test.assertEqual(engine.state, STATE_STRETCH);
    Test.assertEqual(engine.remaining(), 2);
    Test.assertEqual(engine.tick(), EVENT_TICK);
    Test.assertEqual(engine.tick(), EVENT_WORKOUT_DONE);
    Test.assertEqual(engine.state, STATE_DONE);
    Test.assertEqual(engine.completedCount, 1);
    return true;
}

(:test)
function testTwoStretchesEmitStretchDoneBetween(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a", "b"], {"a" => 1, "b" => 1});
    for (var i = 0; i < 5; i++) { engine.tick(); }      // prep
    for (var i = 0; i < 2; i++) { engine.tick(); }      // announce
    engine.tick();                                       // stretch starts (1s)
    Test.assertEqual(engine.tick(), EVENT_STRETCH_DONE);
    Test.assertEqual(engine.state, STATE_ANNOUNCE);
    Test.assertEqual(engine.completedCount, 1);
    Test.assertEqual(engine.position(), 2);
    return true;
}

(:test)
function testDefaultDurationUsedWhenUnset(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {});
    for (var i = 0; i < 5; i++) { engine.tick(); }
    for (var i = 0; i < 3; i++) { engine.tick(); }
    Test.assertEqual(engine.state, STATE_STRETCH);
    Test.assertEqual(engine.remaining(), 30);
    return true;
}

(:test)
function testPauseFreezesAndResumeContinues(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 5});
    engine.tick();
    engine.pause();
    Test.assert(engine.isPaused());
    Test.assertEqual(engine.tick(), EVENT_NONE);
    Test.assertEqual(engine.remaining(), 4);
    engine.resume();
    Test.assertEqual(engine.tick(), EVENT_TICK);
    Test.assertEqual(engine.remaining(), 3);
    return true;
}

(:test)
function testSkipDoesNotCountAsCompleted(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a", "b"], {"a" => 9, "b" => 9});
    for (var i = 0; i < 5; i++) { engine.tick(); }      // prep -> announce "a"
    Test.assertEqual(engine.skip(), EVENT_STRETCH_STARTED);
    Test.assertEqual(engine.position(), 2);
    Test.assertEqual(engine.completedCount, 0);
    Test.assertEqual(engine.skip(), EVENT_WORKOUT_DONE);
    Test.assertEqual(engine.state, STATE_DONE);
    return true;
}

(:test)
function testSkipDuringPrepDoesNothing(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {});
    Test.assertEqual(engine.skip(), EVENT_NONE);
    Test.assertEqual(engine.state, STATE_PREP);
    return true;
}

(:test)
function testEmptyRoutineFinishesAfterPrep(logger as Test.Logger) as Boolean {
    var engine = makeEngine([], {});
    for (var i = 0; i < 4; i++) { engine.tick(); }
    Test.assertEqual(engine.tick(), EVENT_WORKOUT_DONE);
    Test.assertEqual(engine.state, STATE_DONE);
    return true;
}

(:test)
function testProgressAdvances(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 4});
    Test.assert(engine.progress() < 0.01);
    engine.tick();
    Test.assert(engine.progress() > 0.15);
    return true;
}

// --- Additional edge cases ------------------------------------------------

(:test)
function testPauseDuringPrepPreservesPhase(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 5});
    engine.pause();
    Test.assertEqual(engine.state, STATE_PAUSED);
    Test.assertEqual(engine.tick(), EVENT_NONE);
    engine.resume();
    Test.assertEqual(engine.state, STATE_PREP);
    Test.assertEqual(engine.remaining(), 5);
    return true;
}

(:test)
function testPauseDuringAnnouncePreservesPhase(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 5});
    for (var i = 0; i < 5; i++) { engine.tick(); }   // prep -> ANNOUNCE
    engine.tick();                                    // announce 3 -> 2
    engine.pause();
    Test.assertEqual(engine.tick(), EVENT_NONE);
    engine.resume();
    Test.assertEqual(engine.state, STATE_ANNOUNCE);
    Test.assertEqual(engine.remaining(), 2);
    return true;
}

(:test)
function testSkipDuringStretchAnnouncesNext(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a", "b"], {"a" => 9, "b" => 9});
    for (var i = 0; i < 5; i++) { engine.tick(); }   // prep
    for (var i = 0; i < 3; i++) { engine.tick(); }   // announce -> STRETCH
    Test.assertEqual(engine.state, STATE_STRETCH);
    Test.assertEqual(engine.skip(), EVENT_STRETCH_STARTED);
    Test.assertEqual(engine.state, STATE_ANNOUNCE);
    Test.assertEqual(engine.position(), 2);
    Test.assertEqual(engine.completedCount, 0);
    return true;
}

(:test)
function testProgressDuringPauseUsesPrePausePhase(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 10});
    for (var i = 0; i < 5; i++) { engine.tick(); }   // prep
    for (var i = 0; i < 3; i++) { engine.tick(); }   // announce -> STRETCH (10s)
    engine.tick();                                    // 10 -> 9
    var before = engine.progress();
    engine.pause();
    // Paused progress must keep using the stretch duration as phase total,
    // not the prep length.
    var during = engine.progress();
    Test.assert(during > before - 0.001 && during < before + 0.001);
    Test.assert(during > 0.09 && during < 0.11);      // 1/10 elapsed
    return true;
}

(:test)
function testCurrentDurationFallsBackForUnknownId(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["mystery"], {"other" => 5});
    Test.assertEqual(engine.currentDuration(), 30);
    for (var i = 0; i < 5; i++) { engine.tick(); }
    for (var i = 0; i < 3; i++) { engine.tick(); }
    Test.assertEqual(engine.state, STATE_STRETCH);
    Test.assertEqual(engine.remaining(), 30);
    return true;
}

(:test)
function testPositionAndTotalAcrossWholeRun(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a", "b", "c"], {"a" => 1, "b" => 1, "c" => 1});
    Test.assertEqual(engine.total(), 3);
    Test.assertEqual(engine.position(), 1);
    for (var i = 0; i < 5; i++) { engine.tick(); }   // prep
    // Each stretch: 3 announce ticks + 1 stretch tick.
    for (var i = 0; i < 4; i++) { engine.tick(); }   // finish "a"
    Test.assertEqual(engine.position(), 2);
    for (var i = 0; i < 4; i++) { engine.tick(); }   // finish "b"
    Test.assertEqual(engine.position(), 3);
    for (var i = 0; i < 3; i++) { engine.tick(); }   // announce "c"
    Test.assertEqual(engine.tick(), EVENT_WORKOUT_DONE);
    Test.assertEqual(engine.completedCount, 3);
    Test.assertEqual(engine.total(), 3);
    return true;
}

(:test)
function testShuffleSingleElement(logger as Test.Logger) as Boolean {
    var shuffled = WorkoutEngine.shuffle(["only"], new SequenceRandom([0]));
    Test.assertEqual(shuffled.size(), 1);
    Test.assertEqual(shuffled[0], "only");
    return true;
}

(:test)
function testShuffleEmpty(logger as Test.Logger) as Boolean {
    Test.assertEqual(WorkoutEngine.shuffle([], new SequenceRandom([0])).size(), 0);
    return true;
}

(:test)
function testEngineWithDuplicateIds(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a", "a"], {"a" => 1});
    Test.assertEqual(engine.total(), 2);
    for (var i = 0; i < 5; i++) { engine.tick(); }   // prep
    for (var i = 0; i < 3; i++) { engine.tick(); }   // announce
    Test.assertEqual(engine.tick(), EVENT_STRETCH_DONE);
    Test.assertEqual((engine.currentId() as Lang.String), "a");
    for (var i = 0; i < 3; i++) { engine.tick(); }   // announce second "a"
    Test.assertEqual(engine.tick(), EVENT_WORKOUT_DONE);
    Test.assertEqual(engine.completedCount, 2);
    return true;
}

(:test)
function testTickAfterDoneReturnsNone(logger as Test.Logger) as Boolean {
    var engine = makeEngine([], {});
    for (var i = 0; i < 5; i++) { engine.tick(); }
    Test.assertEqual(engine.state, STATE_DONE);
    Test.assertEqual(engine.tick(), EVENT_NONE);
    Test.assertEqual(engine.skip(), EVENT_NONE);
    return true;
}

(:test)
function testResumeWithoutPauseIsNoop(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {});
    engine.resume();
    Test.assertEqual(engine.state, STATE_PREP);
    Test.assert(!engine.isPaused());
    return true;
}

(:test)
function testCurrentIdNullWhenDone(logger as Test.Logger) as Boolean {
    var engine = makeEngine(["a"], {"a" => 1});
    Test.assertEqual((engine.currentId() as Lang.String), "a");
    for (var i = 0; i < 5; i++) { engine.tick(); }
    for (var i = 0; i < 4; i++) { engine.tick(); }
    Test.assertEqual(engine.state, STATE_DONE);
    Test.assert(engine.currentId() == null);
    Test.assertEqual(engine.currentDuration(), 30);   // falls back to default
    return true;
}
