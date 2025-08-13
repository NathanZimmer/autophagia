@tool
class_name Door extends AnimatableBody3D
## TODO

## Domain == time in seconds, Range == rotation in radians [br]
## TODO: better doc
@export var _curve: Curve
## TODO
@export var _rotation_axis: Vector3

var _open := false
var _moving := false
var _base_rotation: Vector3


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_rotation = rotation

    var levers = (find_children("*", "Lever", false)) as Array[Lever]
    for lever in levers:
        lever.turned.connect(_open_close)


## TODO
func _open_close() -> void:
    if _moving:
        return
    _moving = true

    var start_time := Time.get_ticks_msec()
    var end_time := start_time + _curve.max_domain * 1_000

    while Time.get_ticks_msec() < end_time:
        var sample_pos = (Time.get_ticks_msec() - start_time) / 1_000.0
        if _open:
            var end_rotation := _base_rotation + _rotation_axis * _curve.sample_baked(_curve.max_domain)
            rotation = end_rotation - _rotation_axis * _curve.sample_baked(sample_pos)
        else:
            rotation = _base_rotation + _rotation_axis * _curve.sample_baked(sample_pos)

        await get_tree().physics_frame

    _open = !_open
    for lever in (find_children("*", "Lever", false)) as Array[Lever]:
        lever.disable_turning = _open
    _moving = false


## Show warning if we don't have a Lever child
func _get_configuration_warnings() -> PackedStringArray:
    var levers = find_children("*", "Lever", false) as Array[Lever]

    var warnings: PackedStringArray = []
    if levers.is_empty():
        warnings.append("This node needs a Lever child to function.")

    return warnings
