import Toybox.Lang;
import Toybox.WatchUi;

// The "time to stretch" prompt flow: builds the Start / Snooze / Skip
// chooser and reacts to the user's pick.
module AlertFlow {
    function initialView() as [WatchUi.Views, WatchUi.InputDelegates] {
        var view = buildView();
        return [view, new OptionListDelegate(view, new AlertChoiceHandler().method(:onChosen))];
    }

    function push() as Void {
        var view = buildView();
        WatchUi.pushView(view, new OptionListDelegate(view, new AlertChoiceHandler().method(:onChosen)),
                         WatchUi.SLIDE_UP);
    }

    function buildView() as OptionListView {
        return new OptionListView(
            Strings.t("AlertTitle"),
            [
                Strings.t("OptStart"),
                Strings.t("OptSnooze"),
                Strings.t("OptSkip")
            ],
            [Theme.COLOR_SUCCESS, Theme.COLOR_WARM, Theme.COLOR_DANGER],
            true
        );
    }
}

class AlertChoiceHandler {
    function onChosen(index as Number) as Void {
        if (index == 0) {
            Scheduler.consumeAlarm();
            WorkoutFlow.start(true);
        } else if (index == 1) {
            Scheduler.snooze();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else {
            // Explicit skip or BACK: this session is cancelled.
            Scheduler.consumeAlarm();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
