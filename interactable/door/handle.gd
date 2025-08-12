@tool
class_name Handle extends MeshInstance3D
## TODO
# TODO: Reimplement this with curves instead of tweens

signal turned

const TRANS_MODE = Tween.TRANS_QUAD

@export var _locked := false
@export var _stay_turned_when_open := false
@export var _move_duration = 0.5

var open := false
var _tween: Tween


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var click_triggers = find_children("*", "ClickTrigger", false) as Array[ClickTrigger]
    for trigger in click_triggers:
        trigger.triggered.connect(_open)


## Run tweens based on configuration
func _open() -> void:
    if _locked and not open:
        await _run_tween(PI * 0.08, _move_duration / 2)
        await _run_tween(0, _move_duration / 2)
        await _run_tween(PI * 0.08, _move_duration / 2)
        await _run_tween(0, _move_duration / 2)
        return

    if not open:
        await _run_tween(PI * 0.5, _move_duration)
        turned.emit()
        if not _stay_turned_when_open:
            await close()
    else:
        turned.emit()

    open = !open


func close() -> void:
    await _run_tween(0, _move_duration)


## Run Tween to rotate about the z-axis from current rotation to
## `target_rotation` over `duration`
func _run_tween(target_rotation: float, duration: float) -> void:
    _tween = create_tween()
    _tween.tween_property(self, "rotation:z", target_rotation, duration).set_trans(TRANS_MODE)
    await _tween.finished


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers = find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
