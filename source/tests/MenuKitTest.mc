import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

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

(:test)
function testMenuKitMainMenuRowsHaveUniqueIdsAndActions(logger as Test.Logger) as Boolean {
    var rows = MenuKit.mainMenuRows();
    Test.assertEqual(rows.size(), 7);
    var seen = {} as Dictionary<Symbol, Boolean>;
    for (var i = 0; i < rows.size(); i++) {
        var row = rows[i] as Array;
        Test.assert(row[2] instanceof Lang.Method);
        Test.assert(!seen.hasKey(row[1] as Symbol));
        seen.put(row[1] as Symbol, true);
    }
    return true;
}

(:test)
function testMenuKitActionForFindsTheRegisteredMethodOnly(logger as Test.Logger) as Boolean {
    var action = new Lang.Method(MenuKit, :pushAbout);
    var actions = {:about => action} as Dictionary<Symbol, Method>;
    Test.assert(MenuKit.actionFor(actions, new WatchUi.MenuItem("About", null, :about, null)) == action);
    Test.assert(MenuKit.actionFor(actions, new WatchUi.MenuItem("Other", null, :other, null)) == null);
    return true;
}

// The menu tables hold Methods bound to modules; invoking one must reach the
// module function (checked on a pure one, the push actions need a view stack).
(:test)
function testMenuKitModuleMethodsInvokeTheModuleFunction(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        StorageSandbox.useLanguage("eng");
        Test.assertEqual(new Lang.Method(MenuKit, :onOff).invoke(true), "On");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
