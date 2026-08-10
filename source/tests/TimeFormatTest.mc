import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests for clock-time formatting. The pure core (formatWith) is exercised
// for both clock styles; format() itself is checked against the simulator's
// current device setting.

(:test)
function testTimeFormat24HourZeroPads(logger as Test.Logger) as Boolean {
    Test.assertEqual(TimeFormat.formatWith(true, 7, 5), "07:05");
    Test.assertEqual(TimeFormat.formatWith(true, 0, 0), "00:00");
    Test.assertEqual(TimeFormat.formatWith(true, 23, 59), "23:59");
    return true;
}

(:test)
function testTimeFormat12HourMidnightAndNoon(logger as Test.Logger) as Boolean {
    Test.assertEqual(TimeFormat.formatWith(false, 0, 5), "12:05 AM");
    Test.assertEqual(TimeFormat.formatWith(false, 12, 0), "12:00 PM");
    return true;
}

(:test)
function testTimeFormat12HourMorningAndAfternoon(logger as Test.Logger) as Boolean {
    Test.assertEqual(TimeFormat.formatWith(false, 9, 30), "9:30 AM");
    Test.assertEqual(TimeFormat.formatWith(false, 13, 7), "1:07 PM");
    Test.assertEqual(TimeFormat.formatWith(false, 11, 59), "11:59 AM");
    Test.assertEqual(TimeFormat.formatWith(false, 23, 1), "11:01 PM");
    return true;
}

(:test)
function testTimeFormatHonorsDeviceSetting(logger as Test.Logger) as Boolean {
    var is24 = System.getDeviceSettings().is24Hour;
    Test.assertEqual(TimeFormat.format(7, 5), TimeFormat.formatWith(is24, 7, 5));
    return true;
}
