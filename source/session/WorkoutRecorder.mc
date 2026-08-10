import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Lang;

// Thin wrapper around ActivityRecording. Records the routine as a
// Training / Flexibility Training activity so it lands in Garmin Connect
// with every sensor metric the watch captures (heart rate, calories, ...).
// Each finished stretch is stored as a lap, and the number of completed
// stretches is written to a custom FIT session field.
class WorkoutRecorder {
    const STRETCH_COUNT_FIELD_ID = 0;

    hidden var _session as ActivityRecording.Session?;
    hidden var _countField as FitContributor.Field?;

    function start() as Void {
        if (_session != null) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "Stretching",
            :sport => Activity.SPORT_TRAINING,
            :subSport => Activity.SUB_SPORT_FLEXIBILITY_TRAINING
        });
        _countField = createCountField(_session as ActivityRecording.Session);
        (_session as ActivityRecording.Session).start();
    }

    hidden function createCountField(session as ActivityRecording.Session) as FitContributor.Field? {
        try {
            return session.createField(
                "stretches_completed", STRETCH_COUNT_FIELD_ID,
                FitContributor.DATA_TYPE_UINT16,
                {:mesgType => FitContributor.MESG_TYPE_SESSION, :units => "count"});
        } catch (e) {
            return null;
        }
    }

    function isActive() as Boolean {
        return _session != null;
    }

    function addLap() as Void {
        if (_session != null) {
            (_session as ActivityRecording.Session).addLap();
        }
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
            _session = null;
            _countField = null;
        }
    }

    function discard() as Void {
        if (_session != null) {
            (_session as ActivityRecording.Session).discard();
            _session = null;
            _countField = null;
        }
    }
}
