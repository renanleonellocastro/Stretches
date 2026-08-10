import Toybox.Lang;
import Toybox.WatchUi;

// Entry point into a workout: validates the routine and swaps in the
// workout view.
module WorkoutFlow {
    // replaceCurrent: true when coming from the alarm prompt (the prompt is
    // replaced), false when starting from the menu (stacked on top).
    function start(replaceCurrent as Boolean) as Void {
        var ids = RoutineModel.selectedIds();
        if (ids.size() == 0) {
            var msg = new MessageView(
                Strings.t("EmptyRoutineMsg"),
                Theme.COLOR_WARM, 2500);
            if (replaceCurrent) {
                WatchUi.switchToView(msg, new MessageDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.pushView(msg, new MessageDelegate(), WatchUi.SLIDE_LEFT);
            }
            return;
        }
        var engine = new WorkoutEngine(ids, Prefs.getDurations(),
                                       Prefs.getDefaultDuration(), new RandomSource());
        var recorder = new WorkoutRecorder();
        var view = new WorkoutView(engine, recorder);
        var delegate = new WorkoutDelegate(view);
        if (replaceCurrent) {
            WatchUi.switchToView(view, delegate, WatchUi.SLIDE_LEFT);
        } else {
            WatchUi.pushView(view, delegate, WatchUi.SLIDE_LEFT);
        }
    }
}
