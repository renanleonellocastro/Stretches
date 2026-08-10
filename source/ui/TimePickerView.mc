import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Hour:minute picker. START moves hour -> minute -> confirm; BACK moves
// back or cancels. Minutes step by 5.
class TimePickerView extends WatchUi.View {
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
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);

        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 20 / 100, Graphics.FONT_TINY, _title,
                    Graphics.TEXT_JUSTIFY_CENTER);

        var font = Graphics.FONT_NUMBER_HOT;
        var hourText = hour.format("%02d");
        var minText = minute.format("%02d");
        var colonW = dc.getTextWidthInPixels(":", font);
        var hourW = dc.getTextWidthInPixels(hourText, font);
        var minW = dc.getTextWidthInPixels(minText, font);
        var gap = 8;
        var totalW = hourW + colonW + minW + gap * 2;
        var x = (w - totalW) / 2;
        var cy = h * 48 / 100;

        // Active field is accent; the other is white. The colon stays dim.
        dc.setColor(editingMinutes ? Theme.COLOR_TEXT : Theme.COLOR_ACCENT,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, hourText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + hourW + gap, cy, font, ":", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(editingMinutes ? Theme.COLOR_ACCENT : Theme.COLOR_TEXT,
                    Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + hourW + colonW + gap * 2, cy, font, minText,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Chevrons above/below the active field hint at UP/DOWN.
        var fieldX = editingMinutes ? (x + hourW + colonW + gap * 2) : x;
        var fieldW = editingMinutes ? minW : hourW;
        var midX = fieldX + fieldW / 2;
        var fontH = dc.getFontHeight(font);
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        var topY = cy - fontH / 2 - 6;
        var botY = cy + fontH / 2 + 6;
        dc.fillPolygon([[midX - 8, topY], [midX + 8, topY], [midX, topY - 9]]);
        dc.fillPolygon([[midX - 8, botY], [midX + 8, botY], [midX, botY + 9]]);

        // Step hint at the bottom.
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 82 / 100, Graphics.FONT_XTINY,
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
