import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// The scheduled reminder. A calm, button-free notification: it announces that
// it is time to stretch and vibrates once; pressing any button (or tapping)
// simply dismisses it and returns to the home screen, from which the user can
// start a session. There are deliberately no Start / Snooze / Skip actions.
class ReminderView extends WatchUi.View {
    hidden var _alarmDone as Boolean = false;

    function initialize() {
        View.initialize();
    }

    // Vibrate/beep once when the reminder appears (best-effort: an Attention
    // failure must never crash the view).
    function onShow() as Void {
        if (!_alarmDone) {
            _alarmDone = true;
            try {
                AlertKit.alarm();
            } catch (e) {
            }
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawFigure(dc);
        drawText(dc);
    }

    // The same tapered lunge figure as the app icon, in the brand accent.
    hidden function drawFigure(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        _u = (h * 0.28) / 68.0;             // figure height ~28% of the screen
        _cx = w / 2;
        _cy = h * 29 / 100;
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        blob(dc, 40, 13, 7.0);                                           // head
        chain(dc, [[40, 19], [38, 44]], [3.6, 5.0]);                     // torso
        chain(dc, [[38, 44], [54, 52], [55, 73], [61, 74]], [5.2, 3.4, 1.9, 1.5]);  // front leg
        chain(dc, [[38, 44], [24, 58], [13, 72], [8, 71]], [5.2, 3.2, 1.7, 1.5]);   // back leg
        chain(dc, [[39, 24], [49, 32], [56, 42]], [3.6, 2.0, 0.9]);      // front arm
        chain(dc, [[39, 24], [30, 31], [24, 38]], [3.6, 2.0, 0.9]);      // back arm
    }

    hidden var _u as Float = 1.0;
    hidden var _cx as Number = 0;
    hidden var _cy as Number = 0;

    // Filled dot at 0..80-space (x, y) with 0..80-space radius r.
    hidden function blob(dc as Dc, x as Number, y as Number, r as Float) as Void {
        dc.fillCircle(_cx + (x - 34.5) * _u, _cy + (y - 40) * _u, r * _u);
    }

    // A tapered stroke: steps along each segment drawing shrinking dots so the
    // limb narrows to its extremity, mirroring the launcher icon.
    hidden function chain(dc as Dc, pts as Array, rad as Array) as Void {
        for (var s = 0; s < pts.size() - 1; s++) {
            var a = pts[s] as Array;
            var b = pts[s + 1] as Array;
            var ra = rad[s] as Float;
            var rb = rad[s + 1] as Float;
            for (var i = 0; i <= 12; i++) {
                var t = i / 12.0;
                var x = (a[0] as Number) + ((b[0] as Number) - (a[0] as Number)) * t;
                var y = (a[1] as Number) + ((b[1] as Number) - (a[1] as Number)) * t;
                dc.fillCircle(_cx + (x - 34.5) * _u, _cy + (y - 40) * _u,
                              (ra + (rb - ra) * t) * _u);
            }
        }
    }

    hidden function drawText(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 56 / 100, Graphics.FONT_SMALL,
                    Theme.fitText(dc, Strings.t("AlertTitle"), Graphics.FONT_SMALL, w * 88 / 100),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var count = RoutineModel.selectedIds().size();
        if (count == 0) {
            dc.drawText(w / 2, h * 73 / 100, Graphics.FONT_XTINY, Strings.t("EmptyRoutineMsg"),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }
        // Two lines (count, then time) so the longer localized words stay
        // inside the round bezel.
        var mins = (RoutineModel.estimatedTotalSecs() + 59) / 60;
        dc.drawText(w / 2, h * 71 / 100, Graphics.FONT_XTINY,
                    count.toString() + " " + Strings.t("HomeStretchesUnit"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w / 2, h * 80 / 100, Graphics.FONT_XTINY,
                    mins.toString() + " " + Strings.t("HomeMinutesUnit"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

// Any input dismisses the reminder and returns home. When the reminder is the
// cold-launch initial view there is nothing to pop, so swap in the home view;
// otherwise pop back to the home view that is already underneath.
class ReminderDelegate extends WatchUi.BehaviorDelegate {
    hidden var _isInitial as Boolean;

    function initialize(isInitial as Boolean) {
        BehaviorDelegate.initialize();
        _isInitial = isInitial;
    }

    function onKey(evt as WatchUi.KeyEvent) as Boolean {
        return dismiss();
    }

    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        return dismiss();
    }

    function onBack() as Boolean {
        return dismiss();
    }

    hidden function dismiss() as Boolean {
        Scheduler.consumeAlarm();
        if (_isInitial) {
            WatchUi.switchToView(new HomeView(), new HomeDelegate(), WatchUi.SLIDE_DOWN);
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
