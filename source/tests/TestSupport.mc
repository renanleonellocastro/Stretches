import Toybox.Application;
import Toybox.Lang;

// Shared helpers for the integration tests. Nothing here carries (:test),
// so the Run No Evil runner never invokes these directly.
//
// Storage persists between tests within one simulator run, so every test
// that writes Storage must snapshot the keys it may touch and restore them
// before returning — that keeps the suite order-independent.
module StorageSandbox {
    var _saved as Dictionary = {};

    function keys() as Array {
        return [
            Prefs.KEY_SCHEDULES, Prefs.KEY_ROUTINE, Prefs.KEY_DURATIONS,
            Prefs.KEY_DEFAULT_DURATION, Prefs.KEY_TONE, Prefs.KEY_VIBE,
            Prefs.KEY_SNOOZE_UNTIL, Prefs.KEY_PENDING_ALERT,
            Prefs.KEY_NEXT_ALARM, Prefs.KEY_LAST_CHECK,
            Prefs.KEY_SEEDED, Prefs.KEY_LANGUAGE
        ];
    }

    function snapshot() as Void {
        _saved = {};
        var ks = keys();
        for (var i = 0; i < ks.size(); i++) {
            _saved.put(ks[i], Application.Storage.getValue(ks[i] as String));
        }
    }

    function restore() as Void {
        var ks = keys();
        for (var i = 0; i < ks.size(); i++) {
            var key = ks[i] as String;
            var v = _saved.get(key);
            if (v == null) {
                Application.Storage.deleteValue(key);
            } else {
                Application.Storage.setValue(key, v as Application.PropertyValueType);
            }
        }
        resetStringsCache();
    }

    // Strings caches the resolved language table in module vars; drop the
    // cache so the next lookup re-resolves from the (restored) Prefs value.
    function resetStringsCache() as Void {
        Strings._code = null;
        Strings._table = null;
        Strings._eng = null;
    }

    // Pin the runtime language for a test that asserts translated values.
    function useLanguage(code as String) as Void {
        Strings.setLanguage(code);
    }
}
