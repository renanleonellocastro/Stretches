import Toybox.Graphics;
import Toybox.Lang;

// The routine's size and length as two centered lines (count, then minutes),
// shared by the home screen and the reminder. One line overflowed the round
// bezel for the longer localized words (e.g. Spanish "estiramientos").
module RoutineSummary {
    const SECONDS_PER_MINUTE = 60;

    function draw(dc as Dc, count as Number, countY as Number, minutesY as Number) as Void {
        var minutes = roundUpToMinutes(RoutineModel.estimatedTotalSecs());
        drawLine(dc, countY, count.toString() + " " + Strings.t("HomeStretchesUnit"));
        drawLine(dc, minutesY, minutes.toString() + " " + Strings.t("HomeMinutesUnit"));
    }

    // One line of small text, centered horizontally and vertically on y.
    function drawLine(dc as Dc, y as Number, text as String) as Void {
        dc.drawText(dc.getWidth() / 2, y, Graphics.FONT_XTINY, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function roundUpToMinutes(seconds as Number) as Number {
        return (seconds + SECONDS_PER_MINUTE - 1) / SECONDS_PER_MINUTE;
    }
}
