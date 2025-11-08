extends AnimationPlayer

enum State { IDLE, WALKING, AIRBORNE, IMPACT }

# Animation names
const RESET = "player_camera/RESET"
const CAMERA_SWAY = "player_camera/sway"
const CAMERA_IMPACT = "player_camera/impact"

var _state := State.IDLE
var _moving_last_frame := false
var _on_floor_last_frame := false
var _rewind := true

@onready var _footsteps: AudioStreamPlayer3D = %Footsteps


func update_state(
    moving: bool,
    is_on_floor: bool,
) -> void:
    match _state:
        State.IDLE:
            if moving and is_on_floor:
                _state = State.WALKING
                current_animation = CAMERA_SWAY
            elif _on_floor_last_frame and not is_on_floor:
                _state = State.AIRBORNE
                current_animation = RESET
        State.WALKING:
            if not moving:
                _state = State.IDLE
                speed_scale = -1.0 if _rewind else speed_scale
            elif not is_on_floor:
                _state = State.AIRBORNE
                speed_scale = -1.0 if _rewind else speed_scale
        State.AIRBORNE:
            if is_on_floor:
                _state = State.IMPACT
                current_animation = CAMERA_IMPACT
                await animation_finished
                _state = State.IDLE
        State.IMPACT:
            pass

    _moving_last_frame = moving
    _on_floor_last_frame = is_on_floor


func play_footsteps(pitch_scale: float, rand_range: float = 0.0) -> void:
    if _state in [State.IDLE, State.AIRBORNE]:
        return
    _footsteps.pitch_scale = pitch_scale + randf_range(0.0, rand_range)
    _footsteps.play(0.12)


func reset_if_stopped() -> void:
    if _state in [State.IDLE, State.AIRBORNE]:
        current_animation = RESET
        speed_scale = 1.0
        _rewind = true
    elif _state == State.WALKING:
        current_animation = CAMERA_SWAY


func set_rewind() -> void:
    _rewind = false
