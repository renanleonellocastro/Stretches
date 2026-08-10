using Toybox.System;
using Toybox.Lang;

// Runtime i18n facade. Looks translations up in the generated I18n table and
// lets the user switch language at runtime (Connect IQ cannot switch compiled
// string resources on the fly). Foreground only — never referenced from the
// background service path.
module Strings {
    // Module-scope vars cannot be `hidden` in Monkey C; treat as private.
    var _code as Lang.String? = null;    // current effective code
    var _table as Lang.Dictionary? = null;  // cached dict for _code
    var _eng as Lang.Dictionary? = null;    // eng fallback dict

    // Look a key up in the active language, falling back to eng, then to the
    // key itself so a missing translation is still debuggable on screen.
    function t(key as Lang.String) as Lang.String {
        ensureInit();
        var table = _table as Lang.Dictionary;
        var value = table.get(key);
        if (value != null) {
            return value as Lang.String;
        }
        var eng = _eng as Lang.Dictionary;
        value = eng.get(key);
        if (value != null) {
            return value as Lang.String;
        }
        return key;
    }

    // Current effective code (never null).
    function language() as Lang.String {
        ensureInit();
        return _code as Lang.String;
    }

    function setLanguage(code as Lang.String) as Void {
        Prefs.setLanguage(code);
        _code = code;
        _table = I18n.table(code);
        _eng = I18n.table("eng");
    }

    // Map the device system locale to one of the supported codes.
    function systemDefault() as Lang.String {
        var lang = System.getDeviceSettings().systemLanguage;
        if (lang == System.LANGUAGE_POR) { return "por"; }
        if (lang == System.LANGUAGE_SPA) { return "spa"; }
        if (lang == System.LANGUAGE_FRE) { return "fre"; }
        if (lang == System.LANGUAGE_DEU) { return "deu"; }
        if (lang == System.LANGUAGE_ITA) { return "ita"; }
        return "eng";
    }

    function codes() as Lang.Array {
        return I18n.CODES;
    }

    function nativeName(code as Lang.String) as Lang.String {
        return I18n.NAMES[code] as Lang.String;
    }

    // Lazy one-time resolution of the active language from stored prefs (or
    // the system locale when the user has never chosen one).
    function ensureInit() as Void {
        if (_table != null) {
            return;
        }
        var code = Prefs.getLanguage();
        if (code == null) {
            code = systemDefault();
        }
        _code = code;
        _table = I18n.table(code);
        _eng = I18n.table("eng");
    }
}
