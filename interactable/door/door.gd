@tool
class_name Door extends AnimatableBody3D
## TODO
# FIXME: Make colliding with the door while it is opening/closing not janky

## Domain == time in seconds, Range == rotation in radians [br]
## TODO: better doc
@export var _open_curve: Curve = load("uid://mnj03ece6rlx")
## Domain == time in seconds, Range == rotation in radians [br]
## TODO: better doc
@export var _close_curve: Curve = load("uid://beylck0t2x2ne")
## TODO
@export var _rotation_axis: Vector3

var _open := false
var _moving := false
var _base_transform: Transform3D

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _open_curve.bake()
    _close_curve.bake()
    _base_transform = transform

    var levers = (find_children("*", "Lever", false)) as Array[Lever]
    for lever in levers:
        lever.turned.connect(_open_close)


## TODO
func _open_close() -> void:
    if _moving:
        return
    _moving = true

    var curve = _close_curve if _open else _open_curve
    var start_time := Time.get_ticks_msec()
    var end_time := int(start_time + curve.max_domain * 1_000)

    while Time.get_ticks_msec() < end_time:
        var sample_pos := (Time.get_ticks_msec() - start_time) / 1_000.0
        var angle := curve.sample_baked(sample_pos)

        transform = Transform3D(
            Basis(_rotation_axis, angle) * _base_transform.basis,
            _base_transform.origin
        )

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
