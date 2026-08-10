import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Celebration screen shown for a few seconds when the routine completes,
// followed automatically by the save prompt.
class CongratsView extends WatchUi.View {
    const SHOW_MS = 3000;

    hidden var _recorder as WorkoutRecorder;
    hidden var _timer as Timer.Timer?;

    function initialize(recorder as WorkoutRecorder) {
        View.initialize();
        _recorder = recorder;
    }

    function onShow() as Void {
        AlertKit.workoutDone();
        if (_timer == null) {
            _timer = new Timer.Timer();
            (_timer as Timer.Timer).start(method(:onTimeout), SHOW_MS, false);
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTimeout() as Void {
        SaveFlow.prompt(_recorder);
    }

    function goToSavePrompt() as Void {
        SaveFlow.prompt(_recorder);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();

        // Clean success ring: a full frame with a bright accent sweep.
        Theme.drawFrameRing(dc);
        var cx = w / 2;
        var cy = h / 2;
        var r = (cx < cy ? cx : cy) - 3;
        dc.setPenWidth(5);
        dc.setColor(Theme.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 135, 45);
        dc.setPenWidth(1);

        // Centered checkmark badge.
        var badgeR = h / 9;
        dc.setColor(Theme.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, h * 30 / 100, badgeR);
        dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        var bx = cx - badgeR / 2;
        var by = h * 30 / 100;
        dc.drawLine(bx, by, bx + badgeR * 4 / 10, by + badgeR * 5 / 10);
        dc.drawLine(bx + badgeR * 4 / 10, by + badgeR * 5 / 10, bx + badgeR, by - badgeR * 5 / 10);
        dc.setPenWidth(1);

        dc.setColor(Theme.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 56 / 100, Graphics.FONT_MEDIUM,
                    WatchUi.loadResource(Rez.Strings.CongratsTitle) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 70 / 100, Graphics.FONT_TINY,
                    WatchUi.loadResource(Rez.Strings.CongratsBody) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Any key during the celebration jumps straight to the save prompt, so the
// recording can never be lost by accident.
class CongratsDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as CongratsView;

    function initialize(view as CongratsView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.goToSavePrompt();
        return true;
    }

    function onBack() as Boolean {
        _view.goToSavePrompt();
        return true;
    }
}
