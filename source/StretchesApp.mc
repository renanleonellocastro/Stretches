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

    // Delivered when the background service exits while the app is running
    // (or immediately after launch): show the alert prompt.
    function onBackgroundData(data as Application.PersistableType) as Void {
        if (data != null && AlertKit.hasPendingAlert()) {
            AlertFlow.push();
        }
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

// Handles the scheduled temporal event: flags the alarm, lines up the next
// one and asks the system to wake the app so the user gets the
// Start / Snooze / Skip prompt.
(:background)
class StretchesServiceDelegate extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var nowEpoch = Time.now().value();
        var next = Prefs.getNextAlarmEpoch();
        // Temporal events also fire for clamped/fallback registrations;
        // only alert when a real alarm time has been reached.
        if (next != null && nowEpoch >= (next as Number) - 60) {
            Prefs.setPendingAlertTs(nowEpoch);
            var snooze = Prefs.getSnoozeUntil();
            if (snooze != null && (snooze as Number) <= nowEpoch) {
                Prefs.setSnoozeUntil(null);
            }
            Scheduler.registerNext();
            if (Background has :requestApplicationWake) {
                try {
                    Background.requestApplicationWake(
                        Application.loadResource(Rez.Strings.WakeMessage) as String);
                } catch (e) {
                    // Wake requests can be rejected (e.g. during an activity).
                }
            }
            Background.exit(true);
        } else {
            Scheduler.registerNext();
            Background.exit(null);
        }
    }
}
