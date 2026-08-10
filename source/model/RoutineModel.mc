import Toybox.Lang;

// Read-model helpers over the persisted routine (selected stretches and
// their durations).
module RoutineModel {
    function selectedIds() as Array {
        return Prefs.getRoutine();
    }

    function isSelected(id as String) as Boolean {
        var ids = Prefs.getRoutine();
        for (var i = 0; i < ids.size(); i++) {
            if ((ids[i] as String).equals(id)) {
                return true;
            }
        }
        return false;
    }

    function setSelected(id as String, on as Boolean) as Void {
        if (on != isSelected(id)) {
            toggle(id);
        }
    }

    function toggle(id as String) as Void {
        var ids = Prefs.getRoutine();
        var result = [] as Array;
        var found = false;
        for (var i = 0; i < ids.size(); i++) {
            if ((ids[i] as String).equals(id)) {
                found = true;
            } else {
                result = result.add(ids[i]);
            }
        }
        if (!found) {
            result = result.add(id);
        }
        Prefs.setRoutine(result);
    }

    function durationFor(id as String) as Number {
        var durations = Prefs.getDurations();
        var v = durations.get(id);
        return v == null ? Prefs.getDefaultDuration() : v as Number;
    }

    // Total routine length in seconds, including the initial countdown and
    // the per-stretch get-ready lead-ins.
    function estimatedTotalSecs() as Number {
        var ids = Prefs.getRoutine();
        var total = WORKOUT_PREP_SECS;
        for (var i = 0; i < ids.size(); i++) {
            total += WORKOUT_ANNOUNCE_SECS + durationFor(ids[i] as String);
        }
        return total;
    }
}
