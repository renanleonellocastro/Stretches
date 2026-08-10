import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawTitle(dc);
        drawOptions(dc);
    }

    hidden function drawTitle(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * 15 / 100, Graphics.FONT_SMALL, _title,
                    Graphics.TEXT_JUSTIFY_CENTER);
    }

    hidden function drawOptions(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var rowH = rowHeight(h);
        var gap = rowH / 3;
        var y = firstRowTop(h);
        var boxW = (w * 72) / 100;
        var x = (w - boxW) / 2;
        for (var i = 0; i < _labels.size(); i++) {
            drawOption(dc, i, x, y, boxW, rowH);
            y += rowH + gap;
        }
    }

    // Shared row geometry, used by both drawing and touch hit-testing.
    hidden function rowHeight(h as Number) as Number {
        return h / 6;
    }

    hidden function firstRowTop(h as Number) as Number {
        var rowH = rowHeight(h);
        var gap = rowH / 3;
        var totalH = _labels.size() * rowH + (_labels.size() - 1) * gap;
        return h * 34 / 100 + (h * 60 / 100 - totalH) / 2;
    }

    // Index of the option row containing screen y, or -1. Rows get a small
    // halo of half the gap so taps just off a pill still count.
    function rowAt(y as Number) as Number {
        var h = System.getDeviceSettings().screenHeight;
        var rowH = rowHeight(h);
        var gap = rowH / 3;
        var top = firstRowTop(h);
        for (var i = 0; i < _labels.size(); i++) {
            var rowTop = top + i * (rowH + gap);
            if (y >= rowTop - gap / 2 && y < rowTop + rowH + gap / 2) {
                return i;
            }
        }
        return -1;
    }

    // Only the highlighted choice is a colored pill; the rest recede as quiet
    // gray labels so the screen never feels busy.
    hidden function drawOption(dc as Dc, i as Number, x as Number, y as Number,
                               boxW as Number, rowH as Number) as Void {
        if (i == selected) {
            dc.setColor(_colors[i] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, boxW, rowH, rowH / 2);
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
        } else {
            dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(dc.getWidth() / 2, y + rowH / 2, Graphics.FONT_SMALL,
                    _labels[i] as String,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

    // Touch devices: BehaviorDelegate.onSelect discards tap coordinates, so
    // hit-test them here. First tap on a row highlights it; tapping the
    // highlighted row confirms — a stray tap can never trigger the wrong
    // action on the alarm or save prompts.
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var row = _view.rowAt(clickEvent.getCoordinates()[1]);
        if (row < 0) {
            return true;
        }
        if (row == _view.selected) {
            _onChosen.invoke(row);
        } else {
            _view.selected = row;
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onBack() as Boolean {
        _onChosen.invoke(-1);
        return true;
    }
}
