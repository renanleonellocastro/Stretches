import Toybox.Lang;
import Toybox.WatchUi;

// The "time to stretch" reminder flow. It shows a calm, button-free reminder
// (see ReminderView); any input dismisses it. initialView() is used on a cold
// launch from the wake prompt; push() is used when an alarm comes due while the
// app is already open.
module AlertFlow {
    function initialView() as [WatchUi.Views, WatchUi.InputDelegates] {
        return [new ReminderView(), new ReminderDelegate(true)];
    }

    function push() as Void {
        WatchUi.pushView(new ReminderView(), new ReminderDelegate(false),
                         WatchUi.SLIDE_UP);
    }
}
