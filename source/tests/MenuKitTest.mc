import Toybox.Lang;
import Toybox.Test;

// Tests for MenuKit's pure label helpers (the Menu2 builders themselves need
// a live view stack and are exercised manually).

(:test)
function testMenuKitOnOffLabels(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        StorageSandbox.useLanguage("eng");
        Test.assertEqual(MenuKit.onOff(true), "On");
        Test.assertEqual(MenuKit.onOff(false), "Off");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testMenuKitSecondsSub(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        StorageSandbox.useLanguage("eng");
        Test.assertEqual(MenuKit.secondsSub(30), "30 s");
        Test.assertEqual(MenuKit.secondsSub(5), "5 s");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testMenuKitRoutineContains(logger as Test.Logger) as Boolean {
    Test.assert(MenuKit.routineContains(["a", "b"], "b"));
    Test.assert(!MenuKit.routineContains(["a", "b"], "c"));
    Test.assert(!MenuKit.routineContains([], "a"));
    return true;
}

(:test)
function testMenuKitStretchSubInRoutineVsGroup(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        StorageSandbox.useLanguage("eng");
        var entry = StretchCatalog.find("neck_tilt_right") as StretchCatalog.Entry;
        Test.assertEqual(MenuKit.stretchSub(entry, ["neck_tilt_right"]), "In routine");
        Test.assertEqual(MenuKit.stretchSub(entry, []), "Neck");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
