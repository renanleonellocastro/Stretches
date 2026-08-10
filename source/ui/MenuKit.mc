import Toybox.Lang;
import Toybox.WatchUi;

// Builders and delegates for every Menu2 in the app.
module MenuKit {
    function str(res as ResourceId) as String {
        return WatchUi.loadResource(res) as String;
    }

    function pushMainMenu() as Void {
        var menu = new WatchUi.Menu2({:title => str(Rez.Strings.AppName)});
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuStartNow), null, :startNow, null));
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuMyStretches), null, :stretches, null));
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuDurations), null, :durations, null));
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuSchedules), null, :schedules, null));
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuSettings), null, :settings, null));
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuAbout), null, :about, null));
        WatchUi.pushView(menu, new MainMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushStretchPicker() as Void {
        var menu = new WatchUi.Menu2({:title => str(Rez.Strings.MenuMyStretches)});
        var all = StretchCatalog.entries();
        for (var i = 0; i < all.size(); i++) {
            var entry = all[i] as StretchCatalog.Entry;
            menu.addItem(new WatchUi.CheckboxMenuItem(
                str(entry.nameRes), str(StretchCatalog.groupNameRes(entry.group)),
                entry.id, RoutineModel.isSelected(entry.id), null));
        }
        WatchUi.pushView(menu, new StretchPickerDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushDurationsMenu() as Void {
        var ids = RoutineModel.selectedIds();
        if (ids.size() == 0) {
            WatchUi.pushView(new MessageView(str(Rez.Strings.EmptyRoutineMsg), Theme.COLOR_WARM, 2500),
                             new MessageDelegate(), WatchUi.SLIDE_LEFT);
            return;
        }
        var menu = new WatchUi.Menu2({:title => str(Rez.Strings.MenuDurations)});
        for (var i = 0; i < ids.size(); i++) {
            var id = ids[i] as String;
            var entry = StretchCatalog.find(id);
            if (entry == null) {
                continue;
            }
            menu.addItem(new WatchUi.MenuItem(
                str((entry as StretchCatalog.Entry).nameRes),
                RoutineModel.durationFor(id).toString() + " " + str(Rez.Strings.SecondsUnit),
                id, null));
        }
        WatchUi.pushView(menu, new DurationsMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function buildSchedulesMenu() as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => str(Rez.Strings.MenuSchedules)});
        var schedules = Prefs.getSchedules();
        for (var i = 0; i < schedules.size(); i++) {
            var entry = schedules[i] as Array;
            var enabled = entry[2] as Boolean;
            menu.addItem(new WatchUi.MenuItem(
                TimeFormat.format(entry[0] as Number, entry[1] as Number),
                str(enabled ? Rez.Strings.StateOn : Rez.Strings.StateOff),
                i, null));
        }
        menu.addItem(new WatchUi.MenuItem(str(Rez.Strings.MenuAddTime), null, :add, null));
        return menu;
    }

    function pushSchedulesMenu() as Void {
        WatchUi.pushView(buildSchedulesMenu(), new SchedulesMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushSettingsMenu() as Void {
        var menu = new WatchUi.Menu2({:title => str(Rez.Strings.MenuSettings)});
        menu.addItem(new WatchUi.MenuItem(
            str(Rez.Strings.SettingDefaultDuration),
            Prefs.getDefaultDuration().toString() + " " + str(Rez.Strings.SecondsUnit),
            :defaultDuration, null));
        menu.addItem(new WatchUi.CheckboxMenuItem(
            str(Rez.Strings.SettingSound), null, :tone, Prefs.isToneOn(), null));
        menu.addItem(new WatchUi.CheckboxMenuItem(
            str(Rez.Strings.SettingVibration), null, :vibe, Prefs.isVibeOn(), null));
        WatchUi.pushView(menu, new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
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
            WatchUi.pushView(new MessageView(MenuKit.str(Rez.Strings.AboutText), Theme.COLOR_ACCENT, 0),
                             new MessageDelegate(), WatchUi.SLIDE_LEFT);
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
        if (item instanceof WatchUi.CheckboxMenuItem) {
            RoutineModel.setSelected(item.getId() as String, item.isChecked());
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
        if (entry == null) {
            return;
        }
        var view = new NumberPickerView(
            MenuKit.str((entry as StretchCatalog.Entry).nameRes),
            MenuKit.str(Rez.Strings.SecondsUnit),
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
        _item.setSubLabel(value.toString() + " " + MenuKit.str(Rez.Strings.SecondsUnit));
    }
}

class SchedulesMenuDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :add) {
            var view = new TimePickerView(MenuKit.str(Rez.Strings.MenuAddTime), 9, 0);
            var handler = new AddScheduleHandler();
            WatchUi.pushView(view, new TimePickerDelegate(view, handler.method(:onTime)),
                             WatchUi.SLIDE_LEFT);
            return;
        }
        var index = id as Number;
        var schedules = Prefs.getSchedules();
        if (index >= schedules.size()) {
            // Stale menu (a schedule was deleted); rebuild.
            WatchUi.switchToView(MenuKit.buildSchedulesMenu(), new SchedulesMenuDelegate(),
                                 WatchUi.SLIDE_LEFT);
            return;
        }
        pushScheduleItemMenu(index, item);
    }

    hidden function pushScheduleItemMenu(index as Number, parentItem as WatchUi.MenuItem) as Void {
        var schedules = Prefs.getSchedules();
        var entry = schedules[index] as Array;
        var menu = new WatchUi.Menu2({
            :title => TimeFormat.format(entry[0] as Number, entry[1] as Number)});
        menu.addItem(new WatchUi.CheckboxMenuItem(
            MenuKit.str(Rez.Strings.MenuEnabled), null, :enabled, entry[2] as Boolean, null));
        menu.addItem(new WatchUi.MenuItem(MenuKit.str(Rez.Strings.MenuEditTime), null, :edit, null));
        menu.addItem(new WatchUi.MenuItem(MenuKit.str(Rez.Strings.MenuDelete), null, :delete, null));
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
        // Replace the (now stale) schedules menu with a fresh one.
        WatchUi.switchToView(MenuKit.buildSchedulesMenu(), new SchedulesMenuDelegate(),
                             WatchUi.SLIDE_LEFT);
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
        var id = item.getId();
        var schedules = Prefs.getSchedules();
        if (_index >= schedules.size()) {
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
            return;
        }
        if (id == :enabled && item instanceof WatchUi.CheckboxMenuItem) {
            var entry = schedules[_index] as Array;
            entry[2] = item.isChecked();
            Prefs.setSchedules(schedules);
            Scheduler.registerNext();
            _parentItem.setSubLabel(MenuKit.str(
                item.isChecked() ? Rez.Strings.StateOn : Rez.Strings.StateOff));
        } else if (id == :edit) {
            var entry = schedules[_index] as Array;
            var view = new TimePickerView(MenuKit.str(Rez.Strings.MenuEditTime),
                                          entry[0] as Number, entry[1] as Number);
            var handler = new EditScheduleHandler(_index, _parentItem);
            WatchUi.pushView(view, new TimePickerDelegate(view, handler.method(:onTime)),
                             WatchUi.SLIDE_LEFT);
        } else if (id == :delete) {
            var updated = [] as Array;
            for (var i = 0; i < schedules.size(); i++) {
                if (i != _index) {
                    updated = updated.add(schedules[i]);
                }
            }
            Prefs.setSchedules(updated);
            Scheduler.registerNext();
            // Replace this submenu with a rebuilt schedules menu.
            WatchUi.switchToView(MenuKit.buildSchedulesMenu(), new SchedulesMenuDelegate(),
                                 WatchUi.SLIDE_LEFT);
        }
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
            var view = new NumberPickerView(
                MenuKit.str(Rez.Strings.SettingDefaultDuration),
                MenuKit.str(Rez.Strings.SecondsUnit),
                Prefs.getDefaultDuration(), 5, 300, 5);
            var handler = new DefaultDurationHandler(item);
            WatchUi.pushView(view, new NumberPickerDelegate(view, handler.method(:onValue)),
                             WatchUi.SLIDE_LEFT);
        } else if (id == :tone && item instanceof WatchUi.CheckboxMenuItem) {
            Prefs.setToneOn(item.isChecked());
        } else if (id == :vibe && item instanceof WatchUi.CheckboxMenuItem) {
            Prefs.setVibeOn(item.isChecked());
        }
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
        _item.setSubLabel(value.toString() + " " + MenuKit.str(Rez.Strings.SecondsUnit));
    }
}
