@tool
extends Node3D
## TODO

## Path to the image file
@export_file var _image_path: String


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var collision_triggers = (
        find_children("*", "CollisionTrigger", false) as Array[CollisionTrigger]
    )
    for trigger in collision_triggers:
        trigger.triggered.connect(_start_dialog)


## TODO
func _start_dialog() -> void:
    print("TODO")
    queue_free()


## Show warning if we don't have a CollisionTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var collision_triggers = find_children("*", "CollisionTrigger", false)

    var warnings: PackedStringArray = []
    if collision_triggers.is_empty():
        warnings.append("This node needs a CollisionTrigger child to function.")

    return warnings
