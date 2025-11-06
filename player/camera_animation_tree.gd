extends AnimationTree
# TODO: Maybe move this out from under AnimationTree and create a node that controls an
# AnimationTree?? Not sure if that would make more sense

enum State { IDLE, WALKING, AIRBORNE }

var _state := State.IDLE

@onready var _footsteps: AudioStreamPlayer3D = %Footsteps


func update_state(
    velocity: Vector3,
    is_on_floor: bool,
    max_speed: float,
) -> void:
    var normalized_length := velocity.length_squared() / (max_speed ** 2)
    match _state:
        State.IDLE:
            if not is_zero_approx(normalized_length):
                _state = State.WALKING if is_on_floor else State.AIRBORNE
        State.WALKING:
            set("parameters/BlendWalk/blend_amount", normalized_length)
            set("parameters/TimeScaleSway/scale", 2.0 - normalized_length)
            if is_zero_approx(normalized_length) and is_on_floor:
                set("parameters/TimeSeekSway/seek_request", 0.0)
                _state = State.IDLE
            elif not is_on_floor:
                _state = State.AIRBORNE
                set("parameters/BlendWalk/blend_amount", 0.0)
        State.AIRBORNE:
            # FIXME: Sometimes the player lands right before the footstep sound triggers, causing
            # The SFX to play back-to-back
            if is_on_floor:
                _state = State.IDLE if is_zero_approx(normalized_length) else State.WALKING
                set("parameters/OneShotImpact/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func play_footsteps(pitch_scale: float, rand_range: float = 0.0) -> void:
    # _footsteps.pitch_scale = pitch_scale + randf_range(0.0, rand_range)
    if get("parameters/BlendWalk/blend_amount") < 0.5 and rand_range <= 0.0:
        return
    _footsteps.pitch_scale = 0.9 if _footsteps.pitch_scale > 1.0 else 1.1
    _footsteps.play(0.12)
