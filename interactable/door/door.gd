@tool
class_name Door extends AnimatableBody3D
## TODO
# FIXME: Make colliding with the door while it is opening/closing not janky

## Domain == time in seconds, Range == rotation in radians [br]
## TODO: better doc
@export var _curve: Curve = load("uid://mnj03ece6rlx")
## TODO
@export var _rotation_axis: Vector3

var _open := false
var _levers: Array[Lever]
var _tween: Tween
## Store tween interpolated value for changing door direction mid-animation
var _cur_sample_time: float
var _base_rotation: Quaternion


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_rotation = basis.get_rotation_quaternion()

    _levers.assign(find_children("*", "Lever", false))
    for lever in _levers:
        lever.turned.connect(_open_close)


## TODO
func _open_close() -> void:
    if _tween and _tween.is_running():
        _tween.stop()
        _open = !_open
    else:
        for lever in _levers:
            lever.disable_turning = true

    _tween = create_tween()
    if _open:
        _tween.tween_method(
            _set_rotation_from_curve,
            _cur_sample_time,
            0.0,
            _cur_sample_time,
        )
    else:
        _tween.tween_method(
            _set_rotation_from_curve,
            _cur_sample_time,
            _curve.max_domain,
            _curve.max_domain - _cur_sample_time
        )

    await _tween.finished
    _open = !_open
    for lever in _levers:
        lever.disable_turning = _open


## TODO
func _set_rotation_from_curve(sample_time: float) -> void:
    _cur_sample_time = sample_time
    var angle := _curve.sample_baked(sample_time)
    basis = Basis(_base_rotation * Quaternion(_rotation_axis, angle))


## Show warning if we don't have a Lever child
func _get_configuration_warnings() -> PackedStringArray:
    var levers = find_children("*", "Lever", false) as Array[Lever]

    var warnings: PackedStringArray = []
    if levers.is_empty():
        warnings.append("This node needs a Lever child to function.")

    return warnings
