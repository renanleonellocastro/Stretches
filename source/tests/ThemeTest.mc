import Toybox.Lang;
import Toybox.Test;

// Tests for UI helper logic that does not require a device context.

(:test)
function testSplitShortTextSingleLine(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("Neck Tilt", 17);
    Test.assertEqual(lines.size(), 1);
    Test.assertEqual(lines[0], "Neck Tilt");
    return true;
}

(:test)
function testSplitLongTextAtSpace(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("Cross-Body Shoulder R", 17);
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0], "Cross-Body");
    Test.assertEqual(lines[1], "Shoulder R");
    return true;
}

(:test)
function testSplitTextWithoutSpacesStaysSingle(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("Abcdefghijklmnopqrstu", 17);
    Test.assertEqual(lines.size(), 1);
    return true;
}

(:test)
function testGroupColorFallback(logger as Test.Logger) as Boolean {
    Test.assertEqual(Theme.groupColor(99), Theme.COLOR_ACCENT);
    Test.assertEqual(Theme.groupColor(0), Theme.GROUP_COLORS[0] as Lang.Number);
    return true;
}

(:test)
function testTimeFormatValues(logger as Test.Logger) as Boolean {
    // Only the zero-padding logic is asserted here; the 12/24-hour branch
    // depends on device settings which the simulator controls.
    var label = TimeFormat.format(7, 5);
    Test.assert(label.length() >= 4);
    return true;
}
