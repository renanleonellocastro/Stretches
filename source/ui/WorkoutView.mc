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
    hidden var _lapName as String = "";       // stretch currently being held
    hidden var _lapSeconds as Number = 0;

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
        stopTimer();
    }

    hidden function stopTimer() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        keepScreenLit();
        var event = _engine.tick();
        if (event == EVENT_WORKOUT_DONE) {
            finishWorkout(true);
            return;
        }
        applyTickEvent(event);
        WatchUi.requestUpdate();
    }

    // Hold the backlight on so the stretch stays readable throughout.
    // Some devices cap how long the backlight may stay forced on and throw
    // BacklightOnTooLongException — degrade gracefully instead of crashing.
    hidden function keepScreenLit() as Void {
        if (Attention has :backlight) {
            try {
                Attention.backlight(true);
            } catch (e) {
                // Device refused; the screen simply times out as usual.
            }
        }
    }

    hidden function applyTickEvent(event as Number) as Void {
        if (event == EVENT_WORKOUT_STARTED) {
            _recorder.start();
            loadCurrentStretch();
            AlertKit.tone(Attention.TONE_START);
        } else if (event == EVENT_STRETCH_STARTED) {
            loadCurrentStretch();
            beginLap();
        } else if (event == EVENT_STRETCH_DONE) {
            recordCompletedStretch();
            loadCurrentStretch();
        }
    }

    // Remember which stretch is being held so its lap can be labelled.
    hidden function beginLap() as Void {
        _lapName = _fullName;
        _lapSeconds = _engine.currentDuration();
    }

    hidden function recordCompletedStretch() as Void {
        _recorder.logStretchLap(_lapName, _lapSeconds);
        _recorder.setCompletedCount(_engine.completedCount);
        AlertKit.stretchDone();
    }

    // recordFinalLap is true only when the last stretch completed naturally
    // (not skipped), so the final lap carries the right stretch.
    function finishWorkout(recordFinalLap as Boolean) as Void {
        stopTimer();
        if (recordFinalLap) {
            _recorder.logStretchLap(_lapName, _lapSeconds);
        }
        _recorder.setCompletedCount(_engine.completedCount);
        _recorder.stop();
        var congrats = new CongratsView(_recorder);
        WatchUi.switchToView(congrats, new CongratsDelegate(congrats), WatchUi.SLIDE_UP);
    }

    // Ends the workout early (BACK + confirmation).
    function abortWorkout() as Void {
        stopTimer();
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
        if (entry != null) {
            applyStretch(id as String, entry as StretchCatalog.Entry);
        }
    }

    hidden function applyStretch(id as String, entry as StretchCatalog.Entry) as Void {
        _imageId = id;
        _image = WatchUi.loadResource(entry.imageRes) as WatchUi.BitmapResource;
        _groupColor = Theme.groupColor(entry.group);
        _fullName = Strings.t(entry.nameKey);
        _nameLines = Theme.splitTwoLines(_fullName, 17);
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        var state = _engine.state;
        if (state == STATE_PREP) {
            drawCountdown(dc, Strings.t("GetReady"));
        } else if (state == STATE_ANNOUNCE) {
            // Preview the upcoming stretch: name + big centered countdown,
            // no progress ring (mirrors the initial get-ready screen).
            drawCountdown(dc, currentName());
        } else if (state == STATE_DONE) {
            // Transitioning to the congrats view; nothing to draw.
        } else {
            drawStretch(dc);
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
        drawCountdownLabel(dc, label);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 56 / 100, Graphics.FONT_NUMBER_THAI_HOT,
                    _engine.remaining().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawCountdownLabel(dc as Dc, label as String) as Void {
        var w = dc.getWidth();
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        var lines = Theme.splitTwoLines(label, 16);
        var lineH = dc.getFontHeight(Graphics.FONT_SMALL);
        var ly = dc.getHeight() * 22 / 100 - (lines.size() - 1) * lineH / 2;
        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(w / 2, ly, Graphics.FONT_SMALL, lines[i] as String,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            ly += lineH;
        }
    }

    hidden function drawStretch(dc as Dc) as Void {
        Theme.drawProgressRing(dc, _engine.progress(), _groupColor);
        drawStretchHeader(dc);
        drawIllustration(dc);
        drawStretchCountdown(dc);
        if (_engine.isPaused()) {
            drawPausedOverlay(dc, dc.getWidth(), dc.getHeight());
        }
    }

    // Position and name stay in the safe zone near the top so they never
    // touch the progress ring.
    hidden function drawStretchHeader(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 13 / 100, Graphics.FONT_XTINY,
                    _engine.position().toString() + " / " + _engine.total().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 22 / 100, Graphics.FONT_XTINY,
                    Theme.fitText(dc, _fullName, Graphics.FONT_XTINY, w * 72 / 100),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Illustration, centered in the band between the name and the number.
    hidden function drawIllustration(dc as Dc) as Void {
        if (_image == null) {
            return;
        }
        var h = dc.getHeight();
        var bandTop = h * 27 / 100;
        var bandBottom = h * 77 / 100;
        var img = _image as WatchUi.BitmapResource;
        var iy = bandTop + (bandBottom - bandTop - img.getHeight()) / 2;
        dc.drawBitmap((dc.getWidth() - img.getWidth()) / 2, iy, img);
    }

    // A smaller number font keeps it clear of the progress ring near the
    // bottom of the screen.
    hidden function drawStretchCountdown(dc as Dc) as Void {
        dc.setColor(_groupColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 84 / 100, Graphics.FONT_NUMBER_MILD,
                    _engine.remaining().toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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
                    Strings.t("Paused"),
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
            _view.finishWorkout(false);
        }
        WatchUi.requestUpdate();
        return true;
    }

    // BACK asks for confirmation, then ends the workout early.
    function onBack() as Boolean {
        _view.engine().pause();
        var dialog = new WatchUi.Confirmation(
            Strings.t("EndWorkoutQ"));
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
