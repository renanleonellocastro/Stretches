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

// NOTE: Theme.fitText (and the draw* helpers) require a live Graphics.Dc,
// which the Run No Evil harness does not provide — they are exercised only
// on-device/manually and are intentionally untested here.

(:test)
function testSplitExactMaxStaysSingleLine(logger as Test.Logger) as Boolean {
    // Exactly maxChars long: no split needed.
    var lines = Theme.splitTwoLines("ABCDE FGHIJ", 11);
    Test.assertEqual(lines.size(), 1);
    Test.assertEqual(lines[0], "ABCDE FGHIJ");
    return true;
}

(:test)
function testSplitOneOverMaxWithSpace(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("ABCDE FGHIJK", 11);
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0], "ABCDE");
    Test.assertEqual(lines[1], "FGHIJK");
    return true;
}

(:test)
function testSplitOneOverMaxWithoutSpace(logger as Test.Logger) as Boolean {
    // No breakable space: kept as a single (overflowing) line by design.
    var lines = Theme.splitTwoLines("ABCDEFGHIJKL", 11);
    Test.assertEqual(lines.size(), 1);
    Test.assertEqual(lines[0], "ABCDEFGHIJKL");
    return true;
}

(:test)
function testSplitLeadingSpaceStaysSingleLine(logger as Test.Logger) as Boolean {
    // The only space is at index 0; splitting there would give an empty
    // first line, so the text stays on one line (breakAt <= 0 guard).
    var lines = Theme.splitTwoLines(" ABCDEFGHIJKL", 11);
    Test.assertEqual(lines.size(), 1);
    return true;
}

(:test)
function testSplitBreaksAtLastFittingSpace(logger as Test.Logger) as Boolean {
    // Two spaces within the limit: the later one wins.
    var lines = Theme.splitTwoLines("AB CD EFGHIJKLM", 10);
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0], "AB CD");
    Test.assertEqual(lines[1], "EFGHIJKLM");
    return true;
}

(:test)
function testSplitTrailingSpacePreserved(logger as Test.Logger) as Boolean {
    // Trailing space beyond the limit: break happens at the inner space and
    // the trailing space survives on line two (documented current behavior).
    var lines = Theme.splitTwoLines("Hello World ", 8);
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0], "Hello");
    Test.assertEqual(lines[1], "World ");
    return true;
}

(:test)
function testLastSpaceWithinBoundaries(logger as Test.Logger) as Boolean {
    Test.assertEqual(Theme.lastSpaceWithin("NoSpaces", 7), -1);
    // A space exactly at index maxChars still counts (i <= maxChars).
    Test.assertEqual(Theme.lastSpaceWithin("abcd efgh", 4), 4);
    Test.assertEqual(Theme.lastSpaceWithin("abcd efgh", 3), -1);
    return true;
}

(:test)
function testGroupColorEveryGroupDistinct(logger as Test.Logger) as Boolean {
    for (var g = 0; g < StretchCatalog.GROUP_COUNT; g++) {
        Test.assertEqual(Theme.groupColor(g), Theme.GROUP_COLORS[g] as Lang.Number);
    }
    Test.assertEqual(Theme.groupColor(-1), Theme.COLOR_ACCENT);
    return true;
}
