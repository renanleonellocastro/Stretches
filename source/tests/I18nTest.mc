import Toybox.Lang;
import Toybox.Test;

// Integration tests for the generated I18n table and the Strings facade.

(:test)
function testEveryLanguageHasEveryEngKey(logger as Test.Logger) as Boolean {
    var eng = I18n.table("eng");
    var engKeys = eng.keys();
    Test.assert(engKeys.size() > 0);
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var code = codes[c] as String;
        var table = I18n.table(code);
        Test.assertEqualMessage(table.size(), eng.size(),
                                "key count mismatch for " + code);
        for (var k = 0; k < engKeys.size(); k++) {
            var key = engKeys[k] as String;
            var value = table.get(key);
            Test.assertMessage(value != null, "missing " + key + " in " + code);
            // A translation may be empty only when it is empty in English
            // too (deliberately blank resources like FitNoUnit).
            if ((eng.get(key) as String).length() > 0) {
                Test.assertMessage((value as String).length() > 0,
                                   "empty " + key + " in " + code);
            }
        }
    }
    return true;
}

(:test)
function testStringsSetLanguageSwitchesTable(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        var codes = I18n.CODES;
        for (var c = 0; c < codes.size(); c++) {
            var code = codes[c] as String;
            Strings.setLanguage(code);
            Test.assertEqual(Strings.language(), code);
            Test.assertEqual(Prefs.getLanguage(), code);
            Test.assertEqual(Strings.t("AppName"),
                             I18n.table(code).get("AppName") as String);
        }
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testStringsUnknownKeyReturnsKeyItself(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        StorageSandbox.useLanguage("por");
        Test.assertEqual(Strings.t("NoSuchKey_123"), "NoSuchKey_123");
    } finally {
        StorageSandbox.restore();
    }
    return true;
}

(:test)
function testNativeNameNonEmptyForEveryCode(logger as Test.Logger) as Boolean {
    var codes = Strings.codes();
    Test.assertEqual(codes.size(), I18n.CODES.size());
    for (var c = 0; c < codes.size(); c++) {
        var name = Strings.nativeName(codes[c] as String);
        Test.assertMessage(name.length() > 0,
                           "empty native name for " + (codes[c] as String));
    }
    return true;
}

(:test)
function testSystemDefaultIsSupportedCode(logger as Test.Logger) as Boolean {
    var def = Strings.systemDefault();
    var codes = I18n.CODES;
    var found = false;
    for (var c = 0; c < codes.size(); c++) {
        if ((codes[c] as String).equals(def)) {
            found = true;
        }
    }
    Test.assertMessage(found, "systemDefault not in CODES: " + def);
    return true;
}

(:test)
function testStringsFollowSystemWhenLanguageUnset(logger as Test.Logger) as Boolean {
    StorageSandbox.snapshot();
    try {
        Prefs.setLanguage(null);
        StorageSandbox.resetStringsCache();
        Test.assertEqual(Strings.language(), Strings.systemDefault());
        // t() works in the resolved language.
        Test.assert(Strings.t("AppName").length() > 0);
    } finally {
        StorageSandbox.restore();
    }
    return true;
}
