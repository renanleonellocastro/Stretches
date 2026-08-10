import Toybox.Lang;
import Toybox.Test;

// Integrity checks for the stretch catalog.

(:test)
function testCatalogHasAllStretches(logger as Test.Logger) as Boolean {
    Test.assertEqual(StretchCatalog.entries().size(), 34);
    return true;
}

(:test)
function testCatalogIdsAreUnique(logger as Test.Logger) as Boolean {
    var all = StretchCatalog.entries();
    for (var i = 0; i < all.size(); i++) {
        for (var j = i + 1; j < all.size(); j++) {
            var a = all[i] as StretchCatalog.Entry;
            var b = all[j] as StretchCatalog.Entry;
            Test.assertMessage(!a.id.equals(b.id), "duplicate id: " + a.id);
        }
    }
    return true;
}

(:test)
function testCatalogGroupsAreValid(logger as Test.Logger) as Boolean {
    var all = StretchCatalog.entries();
    for (var i = 0; i < all.size(); i++) {
        var entry = all[i] as StretchCatalog.Entry;
        Test.assert(entry.group >= 0 && entry.group < StretchCatalog.GROUP_COUNT);
    }
    return true;
}

(:test)
function testFindReturnsEntry(logger as Test.Logger) as Boolean {
    var entry = StretchCatalog.find("neck_tilt_right");
    Test.assert(entry != null);
    Test.assertEqual((entry as StretchCatalog.Entry).group, StretchCatalog.GROUP_NECK);
    return true;
}

(:test)
function testFindUnknownReturnsNull(logger as Test.Logger) as Boolean {
    Test.assert(StretchCatalog.find("not_a_stretch") == null);
    return true;
}

(:test)
function testRequestedNeckStretchesPresent(logger as Test.Logger) as Boolean {
    // The 18 originally requested stretches must always exist.
    var required = [
        "neck_tilt_right", "neck_tilt_left", "neck_tilt_down", "neck_tilt_up",
        "neck_rot_right", "neck_rot_left", "neck_rot_right_down", "neck_rot_left_down",
        "neck_rot_right_up", "neck_rot_left_up",
        "neck_chest_rot_right_up", "neck_chest_rot_left_up",
        "wrist_flexor_right", "wrist_flexor_left",
        "wrist_extensor_right", "wrist_extensor_left",
        "shoulder_cross_right", "shoulder_cross_left"
    ];
    for (var i = 0; i < required.size(); i++) {
        Test.assertMessage(StretchCatalog.find(required[i] as String) != null,
                           "missing: " + (required[i] as String));
    }
    return true;
}
