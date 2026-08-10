import Toybox.Attention;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Timer;
import Toybox.WatchUi;

// Drives a workout session: initial countdown, per-stretch get-ready and
// stretch phases (with illustration), progress ring, pause and skip.
class WorkoutView extends WatchUi.View {
    hidden var _engine as WorkoutEngine;
    hidden var _recorder as WorkoutRecorder;
    hidden var _timer as Timer.Timer?;
    hidden var _image as WatchUi.BitmapResource?;
    hidden var _imageId as String?;
    hidden var _nameLines as Array = [];
    hidden var _fullName as String = "";
    hidden var _groupColor as Number = Theme.COLOR_ACCENT;

    function initialize(engine as WorkoutEngine, recorder as WorkoutRecorder) {
        View.initialize();
        _engine = engine;
        _recorder = recorder;
        Math.srand(System.getTimer());
    }

    function engine() as WorkoutEngine {
        return _engine;
    }

    function recorder() as WorkoutRecorder {
        return _recorder;
    }

    function onShow() as Void {
        if (_timer == null) {
            _timer = new Timer.Timer();
            (_timer as Timer.Timer).start(method(:onTick), 1000, true);
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        var event = _engine.tick();
        if (event == EVENT_WORKOUT_STARTED) {
            _recorder.start();
            loadCurrentStretch();
            AlertKit.tone(Attention.TONE_START);
        } else if (event == EVENT_STRETCH_STARTED) {
            loadCurrentStretch();
        } else if (event == EVENT_STRETCH_DONE) {
            _recorder.addLap();
            _recorder.setCompletedCount(_engine.completedCount);
            AlertKit.stretchDone();
            loadCurrentStretch();
        } else if (event == EVENT_WORKOUT_DONE) {
            finishWorkout();
            return;
        }
        WatchUi.requestUpdate();
    }

    function finishWorkout() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        _recorder.addLap();
        _recorder.setCompletedCount(_engine.completedCount);
        _recorder.stop();
        var congrats = new CongratsView(_recorder);
        WatchUi.switchToView(congrats, new CongratsDelegate(congrats), WatchUi.SLIDE_UP);
    }

    // Ends the workout early (BACK + confirmation).
    function abortWorkout() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        _recorder.setCompletedCount(_engine.completedCount);
        _recorder.stop();
        if (_recorder.isActive()) {
            SaveFlow.prompt(_recorder);
        } else {
            // Aborted during the initial countdown: nothing was recorded.
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    hidden function loadCurrentStretch() as Void {
        var id = _engine.currentId();
        if (id == null || id.equals(_imageId)) {
            return;
        }
        var entry = StretchCatalog.find(id as String);
        if (entry == null) {
            return;
        }
        _imageId = id;
        _image = WatchUi.loadResource((entry as StretchCatalog.Entry).imageRes) as WatchUi.BitmapResource;
        _groupColor = Theme.groupColor((entry as StretchCatalog.Entry).group);
        _fullName = WatchUi.loadResource((entry as StretchCatalog.Entry).nameRes) as String;
        _nameLines = Theme.splitTwoLines(_fullName, 17);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        var state = _engine.state;
        if (state == STATE_PREP) {
            drawCountdown(dc, WatchUi.loadResource(Rez.Strings.GetReady) as String);
        } else if (state == STATE_ANNOUNCE) {
            // Preview the upcoming stretch: name + big centered countdown,
            // no progress ring (mirrors the initial get-ready screen).
            drawCountdown(dc, currentName());
        } else if (state == STATE_DONE) {
            // Transitioning to the congrats view; nothing to draw.
        } else {
            drawStretch(dc, state);
        }
    }

    hidden function currentName() as String {
        if (_nameLines.size() == 0) {
            return "";
        }
        return _fullName;
    }

    // Full-screen centered countdown used by both the initial get-ready and
    // the per-stretch announce phases. `label` is shown above the number.
    hidden function drawCountdown(dc as Dc, label as String) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        var labelLines = Theme.splitTwoLines(label, 16);
        var lineH = dc.getFontHeight(Graphics.FONT_SMALL);
        var ly = h * 22 / 100 - (labelLines.size() - 1) * lineH / 2;
        for (var i = 0; i < labelLines.size(); i++) {
            dc.drawText(w / 2, ly, Graphics.FONT_SMALL, labelLines[i] as String,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            ly += lineH;
        }
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 56 / 100, Graphics.FONT_NUMBER_THAI_HOT,
                    _engine.remaining().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawStretch(dc as Dc, state as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        Theme.drawProgressRing(dc, _engine.progress(), _groupColor);

        // Position and name stay in the safe zone near the top so they never
        // touch the progress ring.
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 13 / 100, Graphics.FONT_XTINY,
                    _engine.position().toString() + " / " + _engine.total().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 22 / 100, Graphics.FONT_XTINY,
                    Theme.fitText(dc, _fullName, Graphics.FONT_XTINY, w * 72 / 100),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Illustration, centered in the band between the name and the number.
        var bandTop = h * 27 / 100;
        var bandBottom = h * 77 / 100;
        if (_image != null) {
            var img = _image as WatchUi.BitmapResource;
            var iy = bandTop + (bandBottom - bandTop - img.getHeight()) / 2;
            dc.drawBitmap((w - img.getWidth()) / 2, iy, img);
        }

        // Countdown number, centered, inside the ring. A smaller number font
        // keeps it clear of the progress ring near the bottom of the screen.
        dc.setColor(_groupColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 84 / 100, Graphics.FONT_NUMBER_MILD,
                    _engine.remaining().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (_engine.isPaused()) {
            drawPausedOverlay(dc, w, h);
        }
    }

    hidden function drawPausedOverlay(dc as Dc, w as Number, h as Number) as Void {
        var barH = h / 5;
        dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, h / 2 - barH / 2, w, barH);
        dc.setPenWidth(2);
        dc.setColor(Theme.COLOR_WARM, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w / 4, h / 2 - barH / 2, w * 3 / 4, h / 2 - barH / 2);
        dc.drawLine(w / 4, h / 2 + barH / 2, w * 3 / 4, h / 2 + barH / 2);
        dc.setPenWidth(1);
        dc.drawText(w / 2, h / 2, Graphics.FONT_MEDIUM,
                    WatchUi.loadResource(Rez.Strings.Paused) as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class WorkoutDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as WorkoutView;

    function initialize(view as WorkoutView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // START toggles pause.
    function onSelect() as Boolean {
        var engine = _view.engine();
        if (engine.isPaused()) {
            engine.resume();
        } else {
            engine.pause();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // DOWN skips the current stretch.
    function onNextPage() as Boolean {
        var engine = _view.engine();
        var event = engine.skip();
        if (event == EVENT_WORKOUT_DONE) {
            _view.finishWorkout();
        }
        WatchUi.requestUpdate();
        return true;
    }

    // BACK asks for confirmation, then ends the workout early.
    function onBack() as Boolean {
        _view.engine().pause();
        var dialog = new WatchUi.Confirmation(
            WatchUi.loadResource(Rez.Strings.EndWorkoutQ) as String);
        WatchUi.pushView(dialog, new EndWorkoutConfirmDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }
}

class EndWorkoutConfirmDelegate extends WatchUi.ConfirmationDelegate {
    hidden var _view as WorkoutView;

    function initialize(view as WorkoutView) {
        ConfirmationDelegate.initialize();
        _view = view;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _view.abortWorkout();
        } else {
            _view.engine().resume();
        }
        return true;
    }
}
