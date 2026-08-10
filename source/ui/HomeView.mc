import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Timer;
import Toybox.WatchUi;

// Dashboard: next scheduled session, routine summary and the entry point
// to the menu. Also polls for alarms that come due while the app is open.
class HomeView extends WatchUi.View {
    const POLL_MS = 5000;

    hidden var _timer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
            (_timer as Timer.Timer).start(method(:onPoll), POLL_MS, true);
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onPoll() as Void {
        if (AlertKit.checkForegroundDue()) {
            AlertFlow.push();
            return;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawGroupRing(dc);

        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 8, Graphics.FONT_SMALL,
                    WatchUi.loadResource(Rez.Strings.AppName) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Next scheduled alarm.
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 4 + h / 20, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.HomeNext) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_NUMBER_MEDIUM, nextAlarmLabel(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Routine summary: "8 stretches · ~5 min".
        var count = RoutineModel.selectedIds().size();
        var summary;
        if (count == 0) {
            summary = WatchUi.loadResource(Rez.Strings.EmptyRoutineMsg) as String;
            dc.setColor(Theme.COLOR_WARM, Graphics.COLOR_TRANSPARENT);
        } else {
            var mins = (RoutineModel.estimatedTotalSecs() + 59) / 60;
            summary = count.toString() + " " +
                      (WatchUi.loadResource(Rez.Strings.HomeStretchesUnit) as String) +
                      " ~" + mins.toString() + " " +
                      (WatchUi.loadResource(Rez.Strings.HomeMinutesUnit) as String);
            dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(w / 2, (h * 2) / 3, Graphics.FONT_TINY, summary,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, (h * 4) / 5, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.HomeHint) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function nextAlarmLabel() as String {
        var next = Prefs.getNextAlarmEpoch();
        if (next == null) {
            return "--:--";
        }
        var info = Gregorian.info(new Time.Moment(next as Number), Time.FORMAT_SHORT);
        return (info.hour as Number).format("%02d") + ":" + (info.min as Number).format("%02d");
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        MenuKit.pushMainMenu();
        return true;
    }

    function onMenu() as Boolean {
        MenuKit.pushMainMenu();
        return true;
    }
}
