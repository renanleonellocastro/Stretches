import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Hour:minute picker. START moves hour -> minute -> confirm; BACK moves
// back or cancels. Minutes step by 5.
class TimePickerView extends WatchUi.View {
    const GAP = 8;  // pixels between hour, colon and minute

    var hour as Number;
    var minute as Number;
    var editingMinutes as Boolean = false;

    hidden var _title as String;

    function initialize(title as String, initialHour as Number, initialMinute as Number) {
        View.initialize();
        _title = title;
        hour = initialHour;
        minute = initialMinute;
    }

    function adjust(delta as Number) as Void {
        if (editingMinutes) {
            minute = (minute + delta * 5 + 60) % 60;
        } else {
            hour = (hour + delta + 24) % 24;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawTitle(dc);
        drawClockDigits(dc);
        drawActiveFieldChevrons(dc);
        drawStepHint(dc);
    }

    hidden function drawTitle(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 20 / 100, Graphics.FONT_TINY, _title,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Left edge and the hour/colon/minute widths of the centered clock.
    hidden function clockLayout(dc as Dc) as Array {
        var font = Graphics.FONT_NUMBER_HOT;
        var hourW = dc.getTextWidthInPixels(hour.format("%02d"), font);
        var colonW = dc.getTextWidthInPixels(":", font);
        var minW = dc.getTextWidthInPixels(minute.format("%02d"), font);
        var x = (dc.getWidth() - (hourW + colonW + minW + GAP * 2)) / 2;
        return [x, hourW, colonW, minW];
    }

    // Active field is accent; the other is white. The colon stays dim.
    hidden function drawClockDigits(dc as Dc) as Void {
        var font = Graphics.FONT_NUMBER_HOT;
        var cy = dc.getHeight() * 48 / 100;
        var l = clockLayout(dc);
        var x = l[0] as Number;
        var hourW = l[1] as Number;
        var colonW = l[2] as Number;
        var align = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        dc.setColor(editingMinutes ? Theme.COLOR_TEXT : Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, hour.format("%02d"), align);
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + hourW + GAP, cy, font, ":", align);
        dc.setColor(editingMinutes ? Theme.COLOR_ACCENT : Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + hourW + colonW + GAP * 2, cy, font, minute.format("%02d"), align);
    }

    // Chevrons above/below the active field hint at UP/DOWN.
    hidden function drawActiveFieldChevrons(dc as Dc) as Void {
        var cy = dc.getHeight() * 48 / 100;
        var l = clockLayout(dc);
        var x = l[0] as Number;
        var hourW = l[1] as Number;
        var fieldX = editingMinutes ? (x + hourW + (l[2] as Number) + GAP * 2) : x;
        var fieldW = editingMinutes ? (l[3] as Number) : hourW;
        var midX = fieldX + fieldW / 2;
        var half = dc.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2;
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[midX - 8, cy - half - 6], [midX + 8, cy - half - 6], [midX, cy - half - 15]]);
        dc.fillPolygon([[midX - 8, cy + half + 6], [midX + 8, cy + half + 6], [midX, cy + half + 15]]);
    }

    hidden function drawStepHint(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 82 / 100, Graphics.FONT_XTINY,
                    editingMinutes ? "min" : "h", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class TimePickerDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as TimePickerView;
    hidden var _onTime as Method;

    // onTime is invoked with [hour, minute].
    function initialize(view as TimePickerView, onTime as Method) {
        BehaviorDelegate.initialize();
        _view = view;
        _onTime = onTime;
    }

    function onPreviousPage() as Boolean {
        _view.adjust(1);
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        _view.adjust(-1);
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        if (!_view.editingMinutes) {
            _view.editingMinutes = true;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            _onTime.invoke([_view.hour, _view.minute]);
        }
        return true;
    }

    // Touch devices: map taps by screen zone — top third increments, bottom
    // third decrements, the middle confirms (same roles as UP/DOWN/START).
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var h = System.getDeviceSettings().screenHeight;
        var y = clickEvent.getCoordinates()[1];
        if (y < h / 3) {
            return onPreviousPage();
        }
        if (y > (h * 2) / 3) {
            return onNextPage();
        }
        return onSelect();
    }

    function onBack() as Boolean {
        if (_view.editingMinutes) {
            _view.editingMinutes = false;
            WatchUi.requestUpdate();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        return true;
    }
}
