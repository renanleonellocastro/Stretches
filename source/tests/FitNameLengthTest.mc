import Toybox.Lang;
import Toybox.Test;

// The recorder stores each stretch name in a FIT lap string field created
// with :count => 32 — 32 bytes INCLUDING the null terminator — so every
// translated name must encode to at most 31 UTF-8 bytes or it will not fit
// the lap field (see WorkoutRecorder.createFields).

// Helper (no :test): UTF-8 byte length of a string.
function utf8ByteLength(s as String) as Number {
    return s.toUtf8Array().size();
}

const FIT_LAP_NAME_MAX_BYTES = 31;

(:test)
function testUtf8ByteLengthSanity(logger as Test.Logger) as Boolean {
    // Self-check the measuring stick before trusting it below.
    Test.assertEqual(utf8ByteLength("abc"), 3);
    Test.assertEqual(utf8ByteLength(""), 0);
    Test.assertEqual(utf8ByteLength("ã"), 2);     // 2-byte UTF-8 sequence
    Test.assertEqual(utf8ByteLength("Mão"), 4);
    return true;
}

(:test)
function testEveryStretchNameFitsFitLapField(logger as Test.Logger) as Boolean {
    var all = StretchCatalog.entries();
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var code = codes[c] as String;
        var table = I18n.table(code);
        for (var i = 0; i < all.size(); i++) {
            var entry = all[i] as StretchCatalog.Entry;
            var name = table.get(entry.nameKey) as String;
            var bytes = utf8ByteLength(name);
            Test.assertMessage(bytes <= FIT_LAP_NAME_MAX_BYTES,
                "FIT lap name too long (" + bytes + " bytes): "
                + code + ":" + entry.nameKey + " = \"" + name + "\"");
        }
    }
    return true;
}
