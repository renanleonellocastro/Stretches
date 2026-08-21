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

    // Small brand figure (the same forward-stretch pose as the app icon).
    hidden function drawFigure(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var u = (h * 0.24) / 40.0;
        var cx = w / 2;
        var cy = h * 30 / 100;
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth((6.5 * u).toNumber());
        limb(dc, cx, cy, u, [[33, 36], [49, 38]]);       // back
        limb(dc, cx, cy, u, [[35, 37], [31, 60]]);       // arms
        limb(dc, cx, cy, u, [[49, 38], [47, 66]]);       // leg
        limb(dc, cx, cy, u, [[49, 38], [53, 66]]);       // leg
        dc.setPenWidth(1);
        var hr = (6.5 * u).toNumber();
        dc.fillCircle(cx + (27 - 40) * u, cy + (34 - 47) * u, hr);
    }

    // Draws a poly-line in the 0..80 authoring space, centered on (cx, cy).
    hidden function limb(dc as Dc, cx as Number, cy as Number, u as Float,
                         pts as Array) as Void {
        for (var i = 0; i < pts.size() - 1; i++) {
            var a = pts[i] as Array;
            var b = pts[i + 1] as Array;
            dc.drawLine(cx + ((a[0] as Number) - 40) * u, cy + ((a[1] as Number) - 47) * u,
                        cx + ((b[0] as Number) - 40) * u, cy + ((b[1] as Number) - 47) * u);
        }
    }

    hidden function drawText(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 58 / 100, Graphics.FONT_MEDIUM, Strings.t("AlertTitle"),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 74 / 100, Graphics.FONT_XTINY, summary(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function summary() as String {
        var count = RoutineModel.selectedIds().size();
        if (count == 0) {
            return Strings.t("EmptyRoutineMsg");
        }
        var mins = (RoutineModel.estimatedTotalSecs() + 59) / 60;
        return count.toString() + " " + Strings.t("HomeStretchesUnit") +
               " " + mins.toString() + " " + Strings.t("HomeMinutesUnit");
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
