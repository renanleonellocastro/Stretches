import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Application entry point. The class is background-annotated because the
// background service boots through it; methods that run in the background
// context (initialize, onStart, getServiceDelegate) must only touch
// background-safe code. getInitialView / onBackgroundData run in the
// foreground only, so they may use foreground modules (AlertKit, views).
(:background)
class StretchesApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    // Runs in BOTH contexts, so it must stay background-safe (referencing a
    // foreground-only symbol here crashes the background service on boot and
    // the scheduled reminder never fires).
    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StretchesServiceDelegate()];
    }

    // Delivered when the background service exits — including during a cold
    // launch (the user accepted the wake prompt), when no view exists yet, so
    // pushing a view here would crash. The service already flagged the alarm in
    // Storage: getInitialView shows the reminder on launch, and HomeView's poll
    // picks it up when the app is already open.
    function onBackgroundData(data as Application.PersistableType) as Void {
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        Prefs.seedDefaultsIfNeeded();
        Scheduler.registerNext();
        if (AlertKit.hasPendingAlert()) {
            return AlertFlow.initialView();
        }
        return [new HomeView(), new HomeDelegate()];
    }
}

// Handles the scheduled temporal event: flags the alarm, lines up the next one
// and asks the system to wake the app so the user gets the reminder.
(:background)
class StretchesServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    // Fires on the repeating 5-minute poll: if any alarm came due since the
    // last wake, flag it and ask the system to launch the app.
    function onTemporalEvent() as Void {
        var due = Scheduler.backgroundCheck();
        if (due) {
            Prefs.setPendingAlertTs(Time.now().value());
            requestWake();
        }
        Scheduler.registerNext();
        Background.exit(null);
    }

    // The wake prompt is a compiled resource picked by the SYSTEM locale
    // (runtime i18n is foreground-only), so it may differ from the in-app
    // language choice. Acceptable: it is a one-line OS dialog.
    hidden function requestWake() as Void {
        if (Background has :requestApplicationWake) {
            try {
                Background.requestApplicationWake(
                    Application.loadResource(Rez.Strings.WakeMessage) as String);
            } catch (e) {
                // Wake requests can be rejected (e.g. during an activity).
            }
        }
    }
}
