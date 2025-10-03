@tool
extends Node3D
## On collision, sends an image to the colliding node and then queues itself for deletion.
## Colliding node should have a `MessageHandler` child

## Path to the image file
@export_file var _image_path: String


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var collision_triggers := find_children("*", "CollisionTrigger", false)
    for trigger in collision_triggers:
        trigger.triggered.connect(_display_image)


## TODO: Update when MessageHandler is implemented
func _display_image(body: Node3D) -> void:
    var handlers := body.find_children("*", "MessageHandler", false)
    if not handlers.is_empty():
        handlers[0].send_message("TODO")
    queue_free()


## Show warning if we don't have a CollisionTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var collision_triggers := find_children("*", "CollisionTrigger", false)

    var warnings: PackedStringArray = []
    if collision_triggers.is_empty():
        warnings.append("This node needs a CollisionTrigger child to function.")

    return warnings
