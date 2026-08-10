import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// A colorful vertical option chooser used for the alarm prompt
// (Start / Snooze / Skip) and the save prompt (Save / Discard).
// UP/DOWN move the highlight, START confirms, BACK sends -1.
class OptionListView extends WatchUi.View {
    var selected as Number = 0;

    hidden var _title as String;
    hidden var _labels as Array;
    hidden var _colors as Array;
    hidden var _alarmOnShow as Boolean;

    function initialize(title as String, labels as Array, colors as Array,
                        alarmOnShow as Boolean) {
        View.initialize();
        _title = title;
        _labels = labels;
        _colors = colors;
        _alarmOnShow = alarmOnShow;
    }

    function optionCount() as Number {
        return _labels.size();
    }

    function onShow() as Void {
        if (_alarmOnShow) {
            AlertKit.alarm();
            _alarmOnShow = false;
        }
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);

        // Title, with a short accent underline for a designed touch.
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 15 / 100, Graphics.FONT_SMALL, _title,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Option pills: only the highlighted one is colored, the rest are
        // quiet gray outlines, so the screen never feels busy.
        var rowH = h / 6;
        var gap = rowH / 3;
        var totalH = _labels.size() * rowH + (_labels.size() - 1) * gap;
        var y = h * 34 / 100 + (h * 60 / 100 - totalH) / 2;
        var boxW = (w * 72) / 100;
        var x = (w - boxW) / 2;

        for (var i = 0; i < _labels.size(); i++) {
            var color = _colors[i] as Number;
            var radius = rowH / 2;
            if (i == selected) {
                // Highlighted choice: a solid colored pill with dark text.
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(x, y, boxW, rowH, radius);
                dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            } else {
                // Other choices recede as quiet gray labels.
                dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(w / 2, y + rowH / 2, Graphics.FONT_SMALL,
                        _labels[i] as String,
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += rowH + gap;
        }
    }
}

class OptionListDelegate extends WatchUi.BehaviorDelegate {
    hidden var _view as OptionListView;
    hidden var _onChosen as Method;

    // onChosen is invoked with the selected index, or -1 for BACK.
    function initialize(view as OptionListView, onChosen as Method) {
        BehaviorDelegate.initialize();
        _view = view;
        _onChosen = onChosen;
    }

    function onPreviousPage() as Boolean {
        _view.selected = (_view.selected + _view.optionCount() - 1) % _view.optionCount();
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        _view.selected = (_view.selected + 1) % _view.optionCount();
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        _onChosen.invoke(_view.selected);
        return true;
    }

    function onBack() as Boolean {
        _onChosen.invoke(-1);
        return true;
    }
}
