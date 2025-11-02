extends Node3D
## Move this Node3D in the xy plane along a curve and then back again.
## Returns to specified starting point when stopped, starts moving from current position
## When started.

# TODO: Playing the footstep sfx should be reworked so the player can't miss triggering it by
# spamming the W key. This could involve adding a timer or adjusting how _stop_sway() is
# triggered

## Curve used to sway the node along the x-axis. [br]
## * Domain: [0, x] where x is the duration of the animation in seconds [br]
## * Range: [0, y] where y is the maximum position [br]
## The curve should start at y=0 to prevent jumps in position on animation start/end
@export var _x_curve: Curve
## Curve used to sway the node along the y-axis. [br]
## * Domain: [0, x] where x is the duration of the animation in seconds [br]
## * Range: [0, y] where y is the maximum position [br]
## The curve should start at y=0 to prevent jumps in position on animation start/end
@export var _y_curve: Curve
## The point along `_x_curve` to return to when `stop_sway` is called
@export var _starting_point: int
## TODO
## * Domain: [0, x] where x is the duration of the animation in seconds [br]
## * Range: [0, y] where y is the maximum position [br]
## The curve should start and end at y=0 to prevent jumps in position on animation start/end
@export var _impact_curve: Curve

var _tween: Tween
var _return_tween: Tween
var _base_position: Vector3
var _reverse := false
## Store tween interpolated value for cancelling animation and returning to starting point
var _cur_sample_time: float
var _position_last_frame: Vector3
var _velocity_last_frame := 0.0

var is_on_floor: bool

@onready var _footsteps: AudioStreamPlayer3D = %Footsteps


func _ready() -> void:
    _x_curve.bake()
    _y_curve.bake()
    _impact_curve.bake()
    _base_position = position
    _cur_sample_time = _x_curve.get_point_position(_starting_point).x
    _position_last_frame = global_position


func _physics_process(_delta: float) -> void:
    var velocity := _position_last_frame.distance_squared_to(global_position)

    # TODO: Get this working with is_on_floor
    if not is_zero_approx(velocity) and is_zero_approx(_velocity_last_frame):
        _sway()
    elif is_zero_approx(velocity) and not is_zero_approx(_velocity_last_frame):
        _stop_sway()

    _position_last_frame = global_position
    _velocity_last_frame = velocity


## Tween position over `_x_curve` and `_y_curve`.
## On tween `finished` signal, calls itself again
func _sway() -> void:
    if _tween and _tween.is_running():
        return

    if _return_tween and _return_tween.is_running():
        _return_tween.stop()

    _tween = create_tween()
    if _reverse:
        _tween.tween_method(_set_position_from_curve, _cur_sample_time, 0.0, _cur_sample_time)
    else:
        _tween.tween_method(
            _set_position_from_curve,
            _cur_sample_time,
            _x_curve.max_domain,
            _x_curve.max_domain - _cur_sample_time
        )
    _tween.finished.connect(_sway)
    _reverse = !_reverse


## Sets x and y position by sampling `_x_curve` and `_y_curve` at a given time [br]
## ## Parameters [br]
## `sample_time`: Time at which to sample the curve
func _set_position_from_curve(sample_time: float) -> void:
    _cur_sample_time = sample_time
    var x_offset := _x_curve.sample_baked(sample_time)
    var y_offset := _y_curve.sample_baked(sample_time)
    position = Vector3(_base_position.x + x_offset, _base_position.y + y_offset, _base_position.z)

    if _footsteps and y_offset <= _y_curve.min_value:
        _footsteps.pitch_scale = 0.9 + randf_range(0.0, 0.2)
        _footsteps.play()


## Cancels repeating tween and begins tween to return to starting point
func _stop_sway() -> void:
    if _return_tween and _return_tween.is_running():
        return

    if _tween and _tween.is_running():
        _tween.stop()
    else:
        return

    var start_x := _x_curve.get_point_position(_starting_point).x
    _return_tween = create_tween()
    _return_tween.tween_method(
        _set_position_from_curve, _cur_sample_time, start_x, abs(_cur_sample_time - start_x)
    )


func play_jump_impact() -> void:
    _footsteps.pitch_scale = 0.9 + randf_range(0.0, 0.2)
    _footsteps.play(0.12)
    # FIXME: Get this working with camera swaying
    # var tween := create_tween()
    # tween.tween_method(
    #     func(sample_time: float) -> void: position.y = _base_position.y  + _impact_curve.sample_baked(sample_time),
    #     0.0,
    #     _impact_curve.max_domain,
    #     _impact_curve.max_domain
    # )
