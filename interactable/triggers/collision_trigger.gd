class_name CollisionTrigger extends Area3D
## A region of space that can be triggered by a body of specified group entering it. [br]
## Emits the "triggered" signal when these conditions are met.


signal triggered

## Groups that can trigger this area
@export var _groups: Array[StringName]

func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
    for group in body.get_groups():
        if group in _groups:
            triggered.emit()
            return
