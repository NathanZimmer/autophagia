@tool
class_name Door extends AnimatableBody3D
## TODO

## Domain == time in seconds, Range == rotation in radians
@export var _curve: Curve

var _open := false
var _moving := false
var _base_y_rotation: float
var _handles: Array[Handle]

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_y_rotation = rotation.y

    _handles.assign(find_children("*", "Handle", false))
    for handle in _handles:
        handle.turned.connect(_open_close)


## TODO
func _open_close() -> void:
    if _moving:
        return
    _moving = true

    var start_time = Time.get_ticks_msec()
    var end_time = start_time + _curve.max_domain * 1_000

    while Time.get_ticks_msec() < end_time:
        var sample_pos = (Time.get_ticks_msec() - start_time) / 1_000.0
        if _open:
            var end_rotation := _base_y_rotation + _curve.sample_baked(_curve.max_domain)
            rotation.y = end_rotation - _curve.sample_baked(sample_pos)
        else:
            rotation.y = _base_y_rotation + _curve.sample_baked(sample_pos)

        await get_tree().physics_frame

    # FIXME: Make triggering handle close better, don't like how this is rn
    _open = !_open
    for handle in _handles:
        handle.open = _open
        if not _open:
            await handle.close()
    _moving = false


## Show warning if we don't have a Handle child
func _get_configuration_warnings() -> PackedStringArray:
    var warnings: PackedStringArray = []
    if _handles.is_empty():
        warnings.append("This node needs a Handle child to function.")

    return warnings
