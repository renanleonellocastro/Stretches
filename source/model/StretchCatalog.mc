import Toybox.Lang;

// The static catalog of every stretch the app offers. Ids are stable
// strings (they are persisted in Storage); display names and images are
// resources so they localize and render per device.
module StretchCatalog {
    enum Group {
        GROUP_NECK = 0,
        GROUP_WRIST = 1,
        GROUP_SHOULDER = 2,
        GROUP_TORSO = 3,
        GROUP_LEGS = 4
    }

    const GROUP_COUNT = 5;

    class Entry {
        var id as String;
        var nameRes as ResourceId;
        var imageRes as ResourceId;
        var group as Number;

        function initialize(id_ as String, nameRes_ as ResourceId, imageRes_ as ResourceId, group_ as Number) {
            id = id_;
            nameRes = nameRes_;
            imageRes = imageRes_;
            group = group_;
        }
    }

    // Order here is presentation order in the picker menu.
    function entries() as Array {
        return [
            new Entry("neck_tilt_right", Rez.Strings.s_neck_tilt_right, Rez.Drawables.i_neck_tilt_right, GROUP_NECK),
            new Entry("neck_tilt_left", Rez.Strings.s_neck_tilt_left, Rez.Drawables.i_neck_tilt_left, GROUP_NECK),
            new Entry("neck_tilt_down", Rez.Strings.s_neck_tilt_down, Rez.Drawables.i_neck_tilt_down, GROUP_NECK),
            new Entry("neck_tilt_up", Rez.Strings.s_neck_tilt_up, Rez.Drawables.i_neck_tilt_up, GROUP_NECK),
            new Entry("neck_rot_right", Rez.Strings.s_neck_rot_right, Rez.Drawables.i_neck_rot_right, GROUP_NECK),
            new Entry("neck_rot_left", Rez.Strings.s_neck_rot_left, Rez.Drawables.i_neck_rot_left, GROUP_NECK),
            new Entry("neck_rot_right_down", Rez.Strings.s_neck_rot_right_down, Rez.Drawables.i_neck_rot_right_down, GROUP_NECK),
            new Entry("neck_rot_left_down", Rez.Strings.s_neck_rot_left_down, Rez.Drawables.i_neck_rot_left_down, GROUP_NECK),
            new Entry("neck_rot_right_up", Rez.Strings.s_neck_rot_right_up, Rez.Drawables.i_neck_rot_right_up, GROUP_NECK),
            new Entry("neck_rot_left_up", Rez.Strings.s_neck_rot_left_up, Rez.Drawables.i_neck_rot_left_up, GROUP_NECK),
            new Entry("neck_chest_rot_right_up", Rez.Strings.s_neck_chest_rot_right_up, Rez.Drawables.i_neck_chest_rot_right_up, GROUP_NECK),
            new Entry("neck_chest_rot_left_up", Rez.Strings.s_neck_chest_rot_left_up, Rez.Drawables.i_neck_chest_rot_left_up, GROUP_NECK),
            new Entry("wrist_flexor_right", Rez.Strings.s_wrist_flexor_right, Rez.Drawables.i_wrist_flexor_right, GROUP_WRIST),
            new Entry("wrist_flexor_left", Rez.Strings.s_wrist_flexor_left, Rez.Drawables.i_wrist_flexor_left, GROUP_WRIST),
            new Entry("wrist_extensor_right", Rez.Strings.s_wrist_extensor_right, Rez.Drawables.i_wrist_extensor_right, GROUP_WRIST),
            new Entry("wrist_extensor_left", Rez.Strings.s_wrist_extensor_left, Rez.Drawables.i_wrist_extensor_left, GROUP_WRIST),
            new Entry("shoulder_cross_right", Rez.Strings.s_shoulder_cross_right, Rez.Drawables.i_shoulder_cross_right, GROUP_SHOULDER),
            new Entry("shoulder_cross_left", Rez.Strings.s_shoulder_cross_left, Rez.Drawables.i_shoulder_cross_left, GROUP_SHOULDER),
            new Entry("triceps_right", Rez.Strings.s_triceps_right, Rez.Drawables.i_triceps_right, GROUP_SHOULDER),
            new Entry("triceps_left", Rez.Strings.s_triceps_left, Rez.Drawables.i_triceps_left, GROUP_SHOULDER),
            new Entry("chest_opener", Rez.Strings.s_chest_opener, Rez.Drawables.i_chest_opener, GROUP_SHOULDER),
            new Entry("upper_back_reach", Rez.Strings.s_upper_back_reach, Rez.Drawables.i_upper_back_reach, GROUP_SHOULDER),
            new Entry("side_bend_right", Rez.Strings.s_side_bend_right, Rez.Drawables.i_side_bend_right, GROUP_TORSO),
            new Entry("side_bend_left", Rez.Strings.s_side_bend_left, Rez.Drawables.i_side_bend_left, GROUP_TORSO),
            new Entry("torso_twist_right", Rez.Strings.s_torso_twist_right, Rez.Drawables.i_torso_twist_right, GROUP_TORSO),
            new Entry("torso_twist_left", Rez.Strings.s_torso_twist_left, Rez.Drawables.i_torso_twist_left, GROUP_TORSO),
            new Entry("lower_back_child_pose", Rez.Strings.s_lower_back_child_pose, Rez.Drawables.i_lower_back_child_pose, GROUP_TORSO),
            new Entry("hamstring_fold", Rez.Strings.s_hamstring_fold, Rez.Drawables.i_hamstring_fold, GROUP_LEGS),
            new Entry("quad_right", Rez.Strings.s_quad_right, Rez.Drawables.i_quad_right, GROUP_LEGS),
            new Entry("quad_left", Rez.Strings.s_quad_left, Rez.Drawables.i_quad_left, GROUP_LEGS),
            new Entry("calf_right", Rez.Strings.s_calf_right, Rez.Drawables.i_calf_right, GROUP_LEGS),
            new Entry("calf_left", Rez.Strings.s_calf_left, Rez.Drawables.i_calf_left, GROUP_LEGS),
            new Entry("hip_flexor_right", Rez.Strings.s_hip_flexor_right, Rez.Drawables.i_hip_flexor_right, GROUP_LEGS),
            new Entry("hip_flexor_left", Rez.Strings.s_hip_flexor_left, Rez.Drawables.i_hip_flexor_left, GROUP_LEGS)
        ];
    }

    function find(id as String) as Entry? {
        var all = entries();
        for (var i = 0; i < all.size(); i++) {
            var entry = all[i] as Entry;
            if (entry.id.equals(id)) {
                return entry;
            }
        }
        return null;
    }

    function groupNameRes(group as Number) as ResourceId {
        if (group == GROUP_NECK) { return Rez.Strings.GroupNeck; }
        if (group == GROUP_WRIST) { return Rez.Strings.GroupWrist; }
        if (group == GROUP_SHOULDER) { return Rez.Strings.GroupShoulder; }
        if (group == GROUP_TORSO) { return Rez.Strings.GroupTorso; }
        return Rez.Strings.GroupLegs;
    }
}
