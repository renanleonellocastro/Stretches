import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

// Application entry point. The class is background-annotated because the
// background service boots through it; only background-safe code runs in
// that context (getServiceDelegate and the constructor).
(:background)
class StretchesApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new StretchesServiceDelegate()];
    }

    // Delivered when the background service exits — including during a
    // cold launch (the user accepted the wake prompt), when no view exists
    // yet, so pushing a view here would crash. The service already flagged
    // the alarm in Storage: getInitialView shows the prompt on launch, and
    // HomeView's poll picks it up when the app was already open.
    function onBackgroundData(data as Application.PersistableType) as Void {
    }

    // A cold launch from the accepted wake prompt lands here. The whole body
    // is guarded: this path cannot be exercised in the simulator, so any
    // unforeseen error must degrade to the home view (from which the user can
    // still start a session) rather than surface the system "IQ!" crash screen.
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        try {
            Prefs.seedDefaultsIfNeeded();
            Scheduler.registerNext();
            if (AlertKit.hasPendingAlert()) {
                return AlertFlow.initialView();
            }
        } catch (e) {
            // Fall through to the home view below.
        }
        return [new HomeView(), new HomeDelegate()];
    }
}

// Handles the scheduled temporal event: flags the alarm, lines up the next
// one and asks the system to wake the app so the user gets the
// Start / Snooze / Skip prompt.
(:background)
class StretchesServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    // Fires on the repeating 5-minute poll: if any alarm came due since the
    // last wake, flag it and ask the system to launch the app so the user
    // gets the Start / Snooze / Skip prompt.
    function onTemporalEvent() as Void {
        var due = Scheduler.backgroundCheck();
        if (due) {
            Prefs.setPendingAlertTs(Time.now().value());
            requestWake();
        }
        Scheduler.registerNext();
        Background.exit(due ? true : null);
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
