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
    const EMPTY_MESSAGE_LINE_CHARS = 16;

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

    // Fires the alarm prompt for alarms that come due while the app is open
    // — either detected by the foreground clock or flagged by the background
    // service (whose data callback must not push views itself).
    function onPoll() as Void {
        if (AlertKit.checkForegroundDue() || AlertKit.hasPendingAlert()) {
            AlertFlow.push();
            return;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        drawBrand(dc);
        drawNextSession(dc);
        drawSummary(dc);
        drawMenuHint(dc);
    }

    hidden function drawBrand(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 15 / 100, Graphics.FONT_XTINY,
                    (Strings.t("AppName")).toUpper(),
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawNextSession(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var hasAlarm = Prefs.getNextAlarmEpoch() != null;
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 24 / 100, Graphics.FONT_XTINY,
                    Strings.t("HomeNext"),
                    Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(hasAlarm ? Theme.COLOR_TEXT : Theme.COLOR_TEXT_DIM,
                    Graphics.COLOR_TRANSPARENT);
        // FONT_NUMBER_MEDIUM: the label above is pulled up and the summary/menu
        // below are pushed down to give this larger time clear spacing.
        dc.drawText(w / 2, h * 44 / 100, Graphics.FONT_NUMBER_MEDIUM, nextAlarmLabel(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawSummary(dc as Dc) as Void {
        var count = RoutineModel.selectedIds().size();
        if (count == 0) {
            drawEmptyRoutineMessage(dc);
            return;
        }
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        RoutineSummary.draw(dc, count, h * 62 / 100, h * 71 / 100);
    }

    // Wrapped in two lines and centered on the summary's place.
    hidden function drawEmptyRoutineMessage(dc as Dc) as Void {
        var lineHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        var lines = Theme.splitTwoLines(Strings.t("EmptyRoutineMsg"), EMPTY_MESSAGE_LINE_CHARS);
        var y = dc.getHeight() * 66 / 100 - (lines.size() - 1) * lineHeight / 2;
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < lines.size(); i++) {
            RoutineSummary.drawLine(dc, y, lines[i] as String);
            y += lineHeight;
        }
    }

    hidden function drawMenuHint(dc as Dc) as Void {
        Theme.drawPill(dc, dc.getWidth() / 2, dc.getHeight() * 85 / 100,
                       Strings.t("HomeHint"),
                       Graphics.FONT_XTINY, Theme.COLOR_ACCENT, false);
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
