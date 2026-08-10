import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Simple button-friendly value picker (UP increments, DOWN decrements,
// START confirms, BACK cancels). Used for stretch durations.
class NumberPickerView extends WatchUi.View {
    var value as Number;

    hidden var _title as String;
    hidden var _unit as String;
    hidden var _min as Number;
    hidden var _max as Number;
    hidden var _step as Number;

    function initialize(title as String, unit as String, initial as Number,
                        min as Number, max as Number, step as Number) {
        View.initialize();
        _title = title;
        _unit = unit;
        value = initial;
        _min = min;
        _max = max;
        _step = step;
    }

    function increment() as Void {
        value += _step;
        if (value > _max) {
            value = _min;
        }
    }

    function decrement() as Void {
        value -= _step;
        if (value < _min) {
            value = _max;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        drawValueRing(dc);
        drawTitle(dc);
        drawValue(dc);
        drawChevrons(dc, dc.getWidth(), dc.getHeight());
    }

    // Outer ring reflects where the value sits between min and max.
    hidden function drawValueRing(dc as Dc) as Void {
        var span = _max - _min;
        var fraction = span > 0 ? (value - _min).toFloat() / span : 0.0;
        Theme.drawProgressRing(dc, fraction, Theme.COLOR_ACCENT);
    }

    hidden function drawTitle(dc as Dc) as Void {
        var w = dc.getWidth();
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var lines = Theme.splitTwoLines(_title, 18);
        var y = dc.getHeight() * 22 / 100;
        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(w / 2, y, Graphics.FONT_TINY, lines[i] as String,
                        Graphics.TEXT_JUSTIFY_CENTER);
            y += dc.getFontHeight(Graphics.FONT_TINY);
        }
    }

    hidden function drawValue(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 50 / 100, Graphics.FONT_NUMBER_HOT, value.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 68 / 100, Graphics.FONT_TINY, _unit,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Up/down chevron hints just inside the value ring.
    hidden function drawChevrons(dc as Dc, w as Number, h as Number) as Void {
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        var cx = w / 2;
        var topY = h * 13 / 100;
        var botY = h * 87 / 100;
        var top = [[cx - 8, topY], [cx + 8, topY], [cx, topY - 9]];
        var bottom = [[cx - 8, botY], [cx + 8, botY], [cx, botY + 9]];
        dc.fillPolygon(top);
        dc.fillPolygon(bottom);
    }
}

class NumberPickerDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as NumberPickerView;
    hidden var _onValue as Method;

    function initialize(view as NumberPickerView, onValue as Method) {
        BehaviorDelegate.initialize();
        _view = view;
        _onValue = onValue;
    }

    function onPreviousPage() as Boolean {
        _view.increment();
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        _view.decrement();
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        _onValue.invoke(_view.value);
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
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
