import Toybox.Lang;
import Toybox.WatchUi;

// Builders and delegates for every Menu2 in the app.
module MenuKit {
    // Resolve a runtime i18n key to its translated string. Kept named `str`
    // (and taking a key) to minimize churn at the many call sites.
    function str(key as Lang.String) as Lang.String {
        return Strings.t(key);
    }

    function onOff(on as Boolean) as String {
        return str(on ? "StateOn" : "StateOff");
    }

    function secondsSub(seconds as Number) as String {
        return seconds.toString() + " " + str("SecondsUnit");
    }

    function pushMainMenu() as Void {
        var menu = new WatchUi.Menu2({:title => str("AppName")});
        menu.addItem(new WatchUi.MenuItem(str("MenuStartNow"), null, :startNow, null));
        menu.addItem(new WatchUi.MenuItem(str("MenuMyStretches"), null, :stretches, null));
        menu.addItem(new WatchUi.MenuItem(str("MenuDurations"), null, :durations, null));
        menu.addItem(new WatchUi.MenuItem(str("MenuSchedules"), null, :schedules, null));
        menu.addItem(new WatchUi.MenuItem(str("MenuSettings"), null, :settings, null));
        menu.addItem(new WatchUi.MenuItem(str("MenuAbout"), null, :about, null));
        WatchUi.pushView(menu, new MainMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Sub-label showing whether a stretch is part of the routine. `routine`
    // is passed in so the picker reads storage once, not once per item.
    // Plain MenuItems are used because CheckboxMenuItem is not available on
    // every target device (e.g. fr55).
    function stretchSub(entry as StretchCatalog.Entry, routine as Array) as String {
        if (routineContains(routine, entry.id)) {
            return str("InRoutine");
        }
        return str(StretchCatalog.groupNameKey(entry.group));
    }

    function routineContains(routine as Array, id as String) as Boolean {
        for (var i = 0; i < routine.size(); i++) {
            if ((routine[i] as String).equals(id)) {
                return true;
            }
        }
        return false;
    }

    function pushStretchPicker() as Void {
        // Short, single-word title so it never wraps or clips in the Menu2
        // title bar (the menu item that opens it keeps the fuller wording).
        var menu = new WatchUi.Menu2({:title => str("PickerTitle")});
        var routine = RoutineModel.selectedIds();
        var all = StretchCatalog.entries();
        for (var i = 0; i < all.size(); i++) {
            var entry = all[i] as StretchCatalog.Entry;
            menu.addItem(new WatchUi.MenuItem(
                str(entry.nameKey), stretchSub(entry, routine), entry.id, null));
        }
        WatchUi.pushView(menu, new StretchPickerDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushDurationsMenu() as Void {
        var ids = RoutineModel.selectedIds();
        if (ids.size() == 0) {
            pushEmptyRoutineMessage();
            return;
        }
        WatchUi.pushView(buildDurationsMenu(ids), new DurationsMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushEmptyRoutineMessage() as Void {
        WatchUi.pushView(new MessageView(str("EmptyRoutineMsg"), Theme.COLOR_WARM, 2500),
                         new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }

    function buildDurationsMenu(ids as Array) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => str("MenuDurations")});
        for (var i = 0; i < ids.size(); i++) {
            var id = ids[i] as String;
            var entry = StretchCatalog.find(id);
            if (entry != null) {
                menu.addItem(new WatchUi.MenuItem(
                    str((entry as StretchCatalog.Entry).nameKey),
                    secondsSub(RoutineModel.durationFor(id)), id, null));
            }
        }
        return menu;
    }

    function buildSchedulesMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => str("MenuSchedules")});
        var schedules = Prefs.getSchedules();
        for (var i = 0; i < schedules.size(); i++) {
            var entry = schedules[i] as Array;
            var enabled = entry[2] as Boolean;
            menu.addItem(new WatchUi.MenuItem(
                TimeFormat.format(entry[0] as Number, entry[1] as Number),
                str(enabled ? "StateOn" : "StateOff"),
                i, null));
        }
        menu.addItem(new WatchUi.MenuItem(str("MenuAddTime"), null, :add, null));
        return menu;
    }

    function pushSchedulesMenu() as Void {
        WatchUi.pushView(buildSchedulesMenu(), new SchedulesMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Replaces the (now stale) schedules menu with a freshly built one.
    function switchToSchedulesMenu() as Void {
        WatchUi.switchToView(buildSchedulesMenu(), new SchedulesMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushSettingsMenu() as Void {
        var menu = new WatchUi.Menu2({:title => str("MenuSettings")});
        menu.addItem(new WatchUi.MenuItem(
            str("SettingDefaultDuration"),
            secondsSub(Prefs.getDefaultDuration()), :defaultDuration, null));
        menu.addItem(new WatchUi.MenuItem(
            str("SettingSound"), onOff(Prefs.isToneOn()), :tone, null));
        menu.addItem(new WatchUi.MenuItem(
            str("SettingVibration"), onOff(Prefs.isVibeOn()), :vibe, null));
        menu.addItem(new WatchUi.MenuItem(
            str("SettingLanguage"), Strings.nativeName(Strings.language()), :language, null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Language picker: one row per supported code, labelled with its native
    // name. The selected code is the item id.
    function pushLanguageMenu(parentItem as WatchUi.MenuItem) as Void {
        var menu = new WatchUi.Menu2({:title => str("SettingLanguage")});
        var codes = Strings.codes();
        for (var i = 0; i < codes.size(); i++) {
            var code = codes[i] as String;
            menu.addItem(new WatchUi.MenuItem(Strings.nativeName(code), null, code, null));
        }
        WatchUi.pushView(menu, new LanguageMenuDelegate(parentItem), WatchUi.SLIDE_LEFT);
    }

    function pushAbout() as Void {
        WatchUi.pushView(new MessageView(str("AboutText"), Theme.COLOR_ACCENT, 0),
                         new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :startNow) {
            WorkoutFlow.start(false);
        } else if (id == :stretches) {
            MenuKit.pushStretchPicker();
        } else if (id == :durations) {
            MenuKit.pushDurationsMenu();
        } else if (id == :schedules) {
            MenuKit.pushSchedulesMenu();
        } else if (id == :settings) {
            MenuKit.pushSettingsMenu();
        } else if (id == :about) {
            MenuKit.pushAbout();
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class StretchPickerDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        RoutineModel.toggle(id);
        var entry = StretchCatalog.find(id);
        if (entry != null) {
            item.setSubLabel(MenuKit.stretchSub(entry as StretchCatalog.Entry,
                                                RoutineModel.selectedIds()));
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class DurationsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        var entry = StretchCatalog.find(id);
        if (entry != null) {
            pushDurationPicker(id, entry as StretchCatalog.Entry, item);
        }
    }

    hidden function pushDurationPicker(id as String, entry as StretchCatalog.Entry,
                                       item as WatchUi.MenuItem) as Void {
        var view = new NumberPickerView(
            MenuKit.str(entry.nameKey), MenuKit.str("SecondsUnit"),
            RoutineModel.durationFor(id), 5, 300, 5);
        var handler = new DurationValueHandler(id, item);
        WatchUi.pushView(view, new NumberPickerDelegate(view, handler.method(:onValue)),
                         WatchUi.SLIDE_LEFT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class DurationValueHandler {
    hidden var _id as String;
    hidden var _item as WatchUi.MenuItem;

    function initialize(id as String, item as WatchUi.MenuItem) {
        _id = id;
        _item = item;
    }

    function onValue(value as Number) as Void {
        Prefs.setDuration(_id, value);
        _item.setSubLabel(MenuKit.secondsSub(value));
    }
}

class SchedulesMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :add) {
            pushAddTimePicker();
            return;
        }
        var index = id as Number;
        if (index >= Prefs.getSchedules().size()) {
            // Stale menu (a schedule was deleted); rebuild.
            MenuKit.switchToSchedulesMenu();
            return;
        }
        pushScheduleItemMenu(index, item);
    }

    hidden function pushAddTimePicker() as Void {
        var view = new TimePickerView(MenuKit.str("MenuAddTime"), 9, 0);
        var handler = new AddScheduleHandler();
        WatchUi.pushView(view, new TimePickerDelegate(view, handler.method(:onTime)),
                         WatchUi.SLIDE_LEFT);
    }

    hidden function pushScheduleItemMenu(index as Number, parentItem as WatchUi.MenuItem) as Void {
        var schedules = Prefs.getSchedules();
        var entry = schedules[index] as Array;
        var menu = new WatchUi.Menu2({
            :title => TimeFormat.format(entry[0] as Number, entry[1] as Number)});
        menu.addItem(new WatchUi.MenuItem(
            MenuKit.str("MenuEnabled"), MenuKit.onOff(entry[2] as Boolean),
            :enabled, null));
        menu.addItem(new WatchUi.MenuItem(MenuKit.str("MenuEditTime"), null, :edit, null));
        menu.addItem(new WatchUi.MenuItem(MenuKit.str("MenuDelete"), null, :delete, null));
        WatchUi.pushView(menu, new ScheduleItemDelegate(index, parentItem), WatchUi.SLIDE_LEFT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class AddScheduleHandler {
    function onTime(time as Array) as Void {
        var schedules = Prefs.getSchedules();
        schedules = schedules.add([time[0], time[1], true]);
        Prefs.setSchedules(schedules);
        Scheduler.registerNext();
        MenuKit.switchToSchedulesMenu();
    }
}

class ScheduleItemDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _index as Number;
    hidden var _parentItem as WatchUi.MenuItem;

    function initialize(index as Number, parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _index = index;
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var schedules = Prefs.getSchedules();
        if (_index >= schedules.size()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }
        var id = item.getId();
        if (id == :enabled) {
            toggleEnabled(item, schedules);
        } else if (id == :edit) {
            pushEditTimePicker(schedules);
        } else if (id == :delete) {
            deleteSchedule(schedules);
        }
    }

    hidden function toggleEnabled(item as WatchUi.MenuItem, schedules as Array) as Void {
        var entry = schedules[_index] as Array;
        var nowOn = !(entry[2] as Boolean);
        entry[2] = nowOn;
        Prefs.setSchedules(schedules);
        Scheduler.registerNext();
        item.setSubLabel(MenuKit.onOff(nowOn));
        _parentItem.setSubLabel(MenuKit.onOff(nowOn));
    }

    hidden function pushEditTimePicker(schedules as Array) as Void {
        var entry = schedules[_index] as Array;
        var view = new TimePickerView(MenuKit.str("MenuEditTime"),
                                      entry[0] as Number, entry[1] as Number);
        var handler = new EditScheduleHandler(_index, _parentItem);
        WatchUi.pushView(view, new TimePickerDelegate(view, handler.method(:onTime)),
                         WatchUi.SLIDE_LEFT);
    }

    hidden function deleteSchedule(schedules as Array) as Void {
        var updated = [] as Array;
        for (var i = 0; i < schedules.size(); i++) {
            if (i != _index) {
                updated = updated.add(schedules[i]);
            }
        }
        Prefs.setSchedules(updated);
        Scheduler.registerNext();
        MenuKit.switchToSchedulesMenu();
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class EditScheduleHandler {
    hidden var _index as Number;
    hidden var _parentItem as WatchUi.MenuItem;

    function initialize(index as Number, parentItem as WatchUi.MenuItem) {
        _index = index;
        _parentItem = parentItem;
    }

    function onTime(time as Array) as Void {
        var schedules = Prefs.getSchedules();
        if (_index >= schedules.size()) {
            return;
        }
        var entry = schedules[_index] as Array;
        entry[0] = time[0];
        entry[1] = time[1];
        Prefs.setSchedules(schedules);
        Scheduler.registerNext();
        if (_parentItem has :setLabel) {
            _parentItem.setLabel(TimeFormat.format(time[0] as Number, time[1] as Number));
        }
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :defaultDuration) {
            pushDefaultDurationPicker(item);
        } else if (id == :tone) {
            var on = !Prefs.isToneOn();
            Prefs.setToneOn(on);
            item.setSubLabel(MenuKit.onOff(on));
        } else if (id == :vibe) {
            var on = !Prefs.isVibeOn();
            Prefs.setVibeOn(on);
            item.setSubLabel(MenuKit.onOff(on));
        } else if (id == :language) {
            MenuKit.pushLanguageMenu(item);
        }
    }

    hidden function pushDefaultDurationPicker(item as WatchUi.MenuItem) as Void {
        var view = new NumberPickerView(
            MenuKit.str("SettingDefaultDuration"),
            MenuKit.str("SecondsUnit"),
            Prefs.getDefaultDuration(), 5, 300, 5);
        var handler = new DefaultDurationHandler(item);
        WatchUi.pushView(view, new NumberPickerDelegate(view, handler.method(:onValue)),
                         WatchUi.SLIDE_LEFT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class DefaultDurationHandler {
    hidden var _item as WatchUi.MenuItem;

    function initialize(item as WatchUi.MenuItem) {
        _item = item;
    }

    function onValue(value as Number) as Void {
        Prefs.setDefaultDuration(value);
        _item.setSubLabel(MenuKit.secondsSub(value));
    }
}

class LanguageMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _parentItem as WatchUi.MenuItem;

    function initialize(parentItem as WatchUi.MenuItem) {
        Menu2InputDelegate.initialize();
        _parentItem = parentItem;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var code = item.getId() as String;
        Strings.setLanguage(code);
        _parentItem.setSubLabel(Strings.nativeName(code));
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
