@tool
class_name Lever extends MeshInstance3D
## TODO

signal turned

## Domain == time in seconds, Range == rotation in radians [br]
## TODO: better doc
@export var _curve: Curve = load("uid://c7djvmapq1bjn")
## TODO
@export var _rotation_axis: Vector3
## Index of the point on the curve to emit "turned" signal
@export var _emit_point: int

## Can disable animation and just emit the "turned" signal
var disable_turning: bool:
    get:
        return _disable_turning
    set(value):
        _disable_turning = value

var _disable_turning := false
var _tween: Tween
var _emit_time: float
var _base_rotation: Quaternion


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_rotation = basis.get_rotation_quaternion()

    var click_triggers = find_children("*", "ClickTrigger", false) as Array[ClickTrigger]
    for click_trigger in click_triggers:
        click_trigger.triggered.connect(_turn)


## TODO
func _turn() -> void:
    if _tween and _tween.is_running():
        return
    if disable_turning:
        turned.emit()
        return

    _emit_time = _curve.get_point_position(_emit_point).x
    _tween = create_tween()
    _tween.tween_method(
        _set_rotation_from_curve,
        0.0,
        _curve.max_domain,
        _curve.max_domain
    )


## TODO
func _set_rotation_from_curve(sample_time: float) -> void:
    var angle := _curve.sample_baked(sample_time)
    basis = Basis(_base_rotation * Quaternion(_rotation_axis, angle))

    if _emit_time <= sample_time:
        turned.emit()
        _emit_time = INF


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers = find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
