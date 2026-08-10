import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Small transient screen with a colored ring and a message. Closes itself
// after a delay (or on any key via its delegate).
class MessageView extends WatchUi.View {
    hidden var _text as String;
    hidden var _color as Number;
    hidden var _autoCloseMs as Number;
    hidden var _timer as Timer.Timer?;

    function initialize(text as String, color as Number, autoCloseMs as Number) {
        View.initialize();
        _text = text;
        _color = color;
        _autoCloseMs = autoCloseMs;
    }

    function onShow() as Void {
        if (_autoCloseMs > 0) {
            _timer = new Timer.Timer();
            (_timer as Timer.Timer).start(method(:onTimeout), _autoCloseMs, false);
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTimeout() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();

        // Quiet frame with a colored sweep at the top matching the message
        // tone (success / danger / accent).
        Theme.drawFrameRing(dc);
        var cx = w / 2;
        var cy = h / 2;
        var r = (cx < cy ? cx : cy) - 3;
        dc.setPenWidth(5);
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, 118, 62);
        dc.setPenWidth(1);

        // A small colored dot above the text as a gentle focal point.
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, h * 34 / 100, w / 40 + 2);

        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        var lines = Theme.splitTwoLines(_text, 16);
        var lineH = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var y = cy - (lines.size() * lineH) / 2 + h / 20;
        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(cx, y, Graphics.FONT_MEDIUM, lines[i] as String, Graphics.TEXT_JUSTIFY_CENTER);
            y += lineH;
        }
    }
}

class MessageDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
