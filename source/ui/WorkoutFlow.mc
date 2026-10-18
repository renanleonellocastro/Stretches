import Toybox.Lang;
import Toybox.WatchUi;

// Entry point into a workout: validates the routine and stacks the workout
// view on top of the menu.
module WorkoutFlow {
    const EMPTY_ROUTINE_MESSAGE_MS = 2500;

    function start() as Void {
        var ids = RoutineModel.selectedIds();
        if (ids.size() == 0) {
            WatchUi.pushView(new MessageView(Strings.t("EmptyRoutineMsg"), Theme.COLOR_WARM, EMPTY_ROUTINE_MESSAGE_MS),
                             new MessageDelegate(), WatchUi.SLIDE_LEFT);
            return;
        }
        var view = new WorkoutView(newEngine(ids), new WorkoutRecorder());
        WatchUi.pushView(view, new WorkoutDelegate(view), WatchUi.SLIDE_LEFT);
    }

    function newEngine(ids as Array) as WorkoutEngine {
        return new WorkoutEngine(ids, Prefs.getDurations(), Prefs.getDefaultDuration());
    }
}
