import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;

// Records the routine as a Training / Flexibility Training activity so it
// lands in Garmin Connect with every sensor metric the watch captures
// (heart rate, calories, time). Each completed stretch is stored as a lap
// carrying its name and hold time as custom FIT fields, and the total number
// of completed stretches is written to a session field.
class WorkoutRecorder {
    const FIELD_COUNT = 0;
    const FIELD_LAP_NAME = 1;
    const FIELD_LAP_SECONDS = 2;

    hidden var _session as ActivityRecording.Session?;
    hidden var _countField as FitContributor.Field?;
    hidden var _lapNameField as FitContributor.Field?;
    hidden var _lapSecondsField as FitContributor.Field?;

    function start() as Void {
        if (_session != null) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "Stretching",
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_FLEXIBILITY_TRAINING
        });
        createFields();
        (_session as ActivityRecording.Session).start();
    }

    hidden function createFields() as Void {
        var session = _session as ActivityRecording.Session;
        try {
            _countField = session.createField("stretches_completed", FIELD_COUNT,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "count"});
            _lapNameField = session.createField("stretch", FIELD_LAP_NAME,
                FitContributor.DATA_TYPE_STRING,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :count => 24});
            _lapSecondsField = session.createField("hold", FIELD_LAP_SECONDS,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_LAP, :units => "s"});
        } catch (e) {
            // Custom fields are best-effort; recording still works without.
        }
    }

    function isActive() as Boolean {
        return _session != null;
    }

    // Close a lap tagged with the completed stretch's name and hold time.
    function logStretchLap(name as String, seconds as Number) as Void {
        if (_session == null) {
            return;
        }
        if (_lapNameField != null) {
            (_lapNameField as FitContributor.Field).setData(name);
        }
        if (_lapSecondsField != null) {
            (_lapSecondsField as FitContributor.Field).setData(seconds);
        }
        (_session as ActivityRecording.Session).addLap();
    }

    function setCompletedCount(count as Number) as Void {
        if (_countField != null) {
            (_countField as FitContributor.Field).setData(count);
        }
    }

    function stop() as Void {
        if (_session != null) {
            (_session as ActivityRecording.Session).stop();
        }
    }

    function save() as Void {
        if (_session != null) {
            (_session as ActivityRecording.Session).save();
            reset();
        }
    }

    function discard() as Void {
        if (_session != null) {
            (_session as ActivityRecording.Session).discard();
            reset();
        }
    }

    hidden function reset() as Void {
        _session = null;
        _countField = null;
        _lapNameField = null;
        _lapSecondsField = null;
    }
}
