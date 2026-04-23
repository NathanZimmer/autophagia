extends Node3D
## TODO

# TODO: Rename "Container" to something like "Chest"

@onready var _inventory: Inventory = %Inventory


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var click_triggers := find_children("*", "ClickTrigger", false)
    for click_trigger in click_triggers:
        click_trigger.triggered.connect(_send_inventory)


func _send_inventory(body: Node) -> void:
    var handlers := body.find_children("*", "MessageHandler", false)
    if not handlers.is_empty():
        AudioManager.play_pressed()
        handlers[0].send_inventory(_inventory)


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers := find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
