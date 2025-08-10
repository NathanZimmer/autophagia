@tool
extends Node3D
## TODO

## Path to the dialog JSON file. See TODO for formatting
@export_file var _dialog_path: String


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var click_triggers = find_children("*", "ClickTrigger", false) as Array[ClickTrigger]
    for trigger in click_triggers:
        trigger.triggered.connect(_start_dialog)


## TODO
func _start_dialog() -> void:
    print("TODO")


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers = find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
