import Toybox.Lang;
import Toybox.WatchUi;

// Save-or-discard prompt shown after a workout ends.
module SaveFlow {
    function prompt(recorder as WorkoutRecorder) as Void {
        var view = new OptionListView(
            Strings.t("SaveTitle"),
            [
                Strings.t("OptSave"),
                Strings.t("OptDiscard")
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
    const SAVE_INDEX = 0;
    const DISCARD_INDEX = 1;
    const CONFIRMATION_MS = 1800;

    hidden var _recorder as WorkoutRecorder;

    function initialize(recorder as WorkoutRecorder) {
        _recorder = recorder;
    }

    // index -1 (BACK) keeps the prompt on screen: an explicit choice is
    // required so the recording is never lost silently.
    function onChosen(index as Number) as Void {
        if (index == SAVE_INDEX) {
            _recorder.save();
            confirm("SavedMsg", Theme.COLOR_SUCCESS);
        } else if (index == DISCARD_INDEX) {
            _recorder.discard();
            confirm("DiscardedMsg", Theme.COLOR_DANGER);
        }
    }

    hidden function confirm(messageKey as String, color as Number) as Void {
        WatchUi.switchToView(new MessageView(Strings.t(messageKey), color, CONFIRMATION_MS),
                             new MessageDelegate(), WatchUi.SLIDE_UP);
    }
}
