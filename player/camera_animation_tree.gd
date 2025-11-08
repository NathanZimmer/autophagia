extends AnimationTree
## TODO
# FIXME: Going through a portal that changes the player's basis screws up the animation states,
# probably because "is_on_ground()" doesn't work consistently when the basis is non-identity

enum State { IDLE, WALKING, AIRBORNE }

const BLEND_AMOUNT = "parameters/BlendWalk/blend_amount"
const SCALE = "parameters/TimeScaleSway/scale"
const SEEK_REQUEST = "parameters/TimeSeekSway/seek_request"
const ONESHOT_REQUEST = "parameters/OneShotImpact/request"

var _state := State.IDLE
var _tween: Tween

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
            set(BLEND_AMOUNT, normalized_length)
            set(SCALE, 2.0 - normalized_length)
            if is_zero_approx(normalized_length) and is_on_floor:
                set(SEEK_REQUEST, 0.0)
                _state = State.IDLE
            elif not is_on_floor:
                _state = State.AIRBORNE
                _tween = create_tween()
                _tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
                _tween.tween_property(self, BLEND_AMOUNT, 0.0, 1.0 - get(BLEND_AMOUNT))
                _tween.finished.connect(set.bind(SEEK_REQUEST, 0.0))
        State.AIRBORNE:
            if is_on_floor:
                if _tween and _tween.is_running():
                    _tween.stop()
                _state = State.IDLE if is_zero_approx(normalized_length) else State.WALKING
                set(ONESHOT_REQUEST, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func play_footsteps(
    pitch_scale: float,
    rand_range: float = 0.0,
    override_threshold := false,
) -> void:
    if get(BLEND_AMOUNT) < 0.5 and not override_threshold:
        return
    _footsteps.pitch_scale = pitch_scale + randf_range(0.0, rand_range)
    _footsteps.play()
