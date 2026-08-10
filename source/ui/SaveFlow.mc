import Toybox.Lang;
import Toybox.WatchUi;

// Save-or-discard prompt shown after a workout ends.
module SaveFlow {
    function prompt(recorder as WorkoutRecorder) as Void {
        var view = new OptionListView(
            WatchUi.loadResource(Rez.Strings.SaveTitle) as String,
            [
                WatchUi.loadResource(Rez.Strings.OptSave) as String,
                WatchUi.loadResource(Rez.Strings.OptDiscard) as String
            ],
            [Theme.COLOR_SUCCESS, Theme.COLOR_DANGER],
            false
        );
        var handler = new SaveChoiceHandler(recorder);
        WatchUi.switchToView(view, new OptionListDelegate(view, handler.method(:onChosen)),
                             WatchUi.SLIDE_UP);
    }
}

class SaveChoiceHandler {
    hidden var _recorder as WorkoutRecorder;

    function initialize(recorder as WorkoutRecorder) {
        _recorder = recorder;
    }

    function onChosen(index as Number) as Void {
        if (index == 0) {
            _recorder.save();
            WatchUi.switchToView(
                new MessageView(WatchUi.loadResource(Rez.Strings.SavedMsg) as String,
                                Theme.COLOR_SUCCESS, 1800),
                new MessageDelegate(), WatchUi.SLIDE_UP);
        } else if (index == 1) {
            _recorder.discard();
            WatchUi.switchToView(
                new MessageView(WatchUi.loadResource(Rez.Strings.DiscardedMsg) as String,
                                Theme.COLOR_DANGER, 1800),
                new MessageDelegate(), WatchUi.SLIDE_UP);
        }
        // index -1 (BACK): keep the prompt on screen, an explicit choice is
        // required so the recording is never lost silently.
    }
}
