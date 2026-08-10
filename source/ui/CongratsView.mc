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
        Theme.drawGroupRing(dc);

        dc.setColor(Theme.COLOR_SUCCESS, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 3, Graphics.FONT_MEDIUM,
                    WatchUi.loadResource(Rez.Strings.CongratsTitle) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2, Graphics.FONT_SMALL,
                    WatchUi.loadResource(Rez.Strings.CongratsBody) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // A row of celebratory dots in the group colors.
        var dotR = w / 40 + 2;
        var spacing = dotR * 3;
        var x = w / 2 - 2 * spacing;
        for (var i = 0; i < 5; i++) {
            dc.setColor(Theme.GROUP_COLORS[i] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x, (h * 2) / 3, dotR);
            x += spacing;
        }
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
