import Toybox.Lang;
import Toybox.System;

// Clock-time formatting that honors the device's 12/24-hour setting.
module TimeFormat {
    function format(hour as Number, minute as Number) as String {
        return formatWith(System.getDeviceSettings().is24Hour, hour, minute);
    }

    // Pure formatting core, split out so both clock styles are unit-testable
    // (System.DeviceSettings.is24Hour cannot be forced from a test).
    function formatWith(is24Hour as Boolean, hour as Number, minute as Number) as String {
        if (is24Hour) {
            return hour.format("%02d") + ":" + minute.format("%02d");
        }
        var suffix = hour < 12 ? " AM" : " PM";
        var h12 = hour % 12;
        if (h12 == 0) {
            h12 = 12;
        }
        return h12.toString() + ":" + minute.format("%02d") + suffix;
    }
}
