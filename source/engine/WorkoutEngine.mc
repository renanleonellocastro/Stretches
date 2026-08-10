import Toybox.Lang;
import Toybox.Math;

// Source of pseudo-randomness for the workout order. Tests substitute a
// deterministic subclass.
class RandomSource {
    function initialize() {
    }

    function next(bound as Number) as Number {
        return Math.rand() % bound;
    }
}

// Workout phases.
enum WorkoutState {
    STATE_PREP = 0,      // initial 5-second countdown
    STATE_ANNOUNCE = 1,  // stretch shown, 3-second get-ready countdown
    STATE_STRETCH = 2,   // stretch running
    STATE_PAUSED = 3,
    STATE_DONE = 4
}

// Tick events, consumed by the view to trigger vibration/tones/laps.
enum WorkoutEvent {
    EVENT_NONE = 0,
    EVENT_TICK = 1,
    EVENT_WORKOUT_STARTED = 2,  // prep finished, first stretch announced
    EVENT_STRETCH_STARTED = 3,  // announce finished, stretch running
    EVENT_STRETCH_DONE = 4,     // stretch finished, next one announced
    EVENT_WORKOUT_DONE = 5
}

const WORKOUT_PREP_SECS = 5;
const WORKOUT_ANNOUNCE_SECS = 3;

// The workout state machine. It is driven by a 1-second tick from the view
// layer and knows nothing about UI, timers, sensors or persistence, which
// keeps it fully unit-testable.
class WorkoutEngine {
    hidden var _order as Array = [];
    hidden var _durations as Dictionary = {};
    hidden var _defaultDuration as Number = 30;
    hidden var _index as Number = 0;
    hidden var _remaining as Number = WORKOUT_PREP_SECS;
    hidden var _stateBeforePause as Number = STATE_PREP;

    var state as Number = STATE_PREP;
    var completedCount as Number = 0;

    function initialize(routineIds as Array, durations as Dictionary,
                        defaultDuration as Number, rng as RandomSource) {
        _order = shuffle(routineIds, rng);
        _durations = durations;
        _defaultDuration = defaultDuration;
        _remaining = WORKOUT_PREP_SECS;
    }

    // Fisher-Yates shuffle; returns a new array, input untouched.
    static function shuffle(ids as Array, rng as RandomSource) as Array {
        var order = [] as Array;
        for (var i = 0; i < ids.size(); i++) {
            order = order.add(ids[i]);
        }
        for (var i = order.size() - 1; i > 0; i--) {
            var j = rng.next(i + 1);
            var tmp = order[i];
            order[i] = order[j];
            order[j] = tmp;
        }
        return order;
    }

    function currentId() as String? {
        if (_index >= _order.size()) {
            return null;
        }
        return _order[_index] as String;
    }

    function currentDuration() as Number {
        var id = currentId();
        if (id == null) {
            return _defaultDuration;
        }
        var v = _durations.get(id);
        return v == null ? _defaultDuration : v as Number;
    }

    function remaining() as Number {
        return _remaining;
    }

    function position() as Number {
        return _index + 1;
    }

    function total() as Number {
        return _order.size();
    }

    // Fraction of the current phase already elapsed, 0.0 .. 1.0.
    function progress() as Float {
        var phaseTotal = WORKOUT_PREP_SECS;
        if (state == STATE_ANNOUNCE) {
            phaseTotal = WORKOUT_ANNOUNCE_SECS;
        } else if (state == STATE_STRETCH || (state == STATE_PAUSED && _stateBeforePause == STATE_STRETCH)) {
            phaseTotal = currentDuration();
        }
        if (phaseTotal <= 0) {
            return 1.0;
        }
        return (phaseTotal - _remaining).toFloat() / phaseTotal;
    }

    function pause() as Void {
        if (state == STATE_PREP || state == STATE_ANNOUNCE || state == STATE_STRETCH) {
            _stateBeforePause = state;
            state = STATE_PAUSED;
        }
    }

    function resume() as Void {
        if (state == STATE_PAUSED) {
            state = _stateBeforePause;
        }
    }

    function isPaused() as Boolean {
        return state == STATE_PAUSED;
    }

    // Skip the current stretch without counting it as completed.
    function skip() as Number {
        if (state != STATE_ANNOUNCE && state != STATE_STRETCH) {
            return EVENT_NONE;
        }
        return advance(false);
    }

    // Advance the 1-second clock. Returns the Event that occurred.
    function tick() as Number {
        if (state == STATE_PAUSED || state == STATE_DONE) {
            return EVENT_NONE;
        }
        _remaining -= 1;
        if (_remaining > 0) {
            return EVENT_TICK;
        }
        if (state == STATE_PREP) {
            if (_order.size() == 0) {
                state = STATE_DONE;
                return EVENT_WORKOUT_DONE;
            }
            state = STATE_ANNOUNCE;
            _remaining = WORKOUT_ANNOUNCE_SECS;
            return EVENT_WORKOUT_STARTED;
        }
        if (state == STATE_ANNOUNCE) {
            state = STATE_STRETCH;
            _remaining = currentDuration();
            return EVENT_STRETCH_STARTED;
        }
        // STATE_STRETCH finished
        completedCount += 1;
        return advance(true);
    }

    hidden function advance(completed as Boolean) as Number {
        _index += 1;
        if (_index >= _order.size()) {
            state = STATE_DONE;
            return EVENT_WORKOUT_DONE;
        }
        state = STATE_ANNOUNCE;
        _remaining = WORKOUT_ANNOUNCE_SECS;
        return completed ? EVENT_STRETCH_DONE : EVENT_STRETCH_STARTED;
    }
}
