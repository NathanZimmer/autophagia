@tool
extends Node3D
## On click, displays the dialog associated with this NPC

## Path to the dialog file
@export_file var _dialog_path: String

var _dialog: DialogTree


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _dialog = DialogTree.new(_dialog_path)

    var click_triggers := find_children("*", "ClickTrigger", false)
    for click_trigger in click_triggers:
        click_trigger.triggered.connect(_start_dialog)


func _start_dialog(body: Node) -> void:
    var handlers := body.find_children("*", "MessageHandler", false)
    if not handlers.is_empty():
        TwoDAudioManager._play_pressed()
        handlers[0].send_dialog(_dialog)


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers := find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
