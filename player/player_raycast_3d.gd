class_name PlayerRayCast3D extends RayCast3D
## When an input event is received, pipes input to the first `ClickTrigger` node
## that is colliding with this raycast


func _unhandled_input(event: InputEvent) -> void:
    var collided := get_collider()
    if not collided or not collided is ClickTrigger:
        return

    # TODO: Create constant or expose as @export to make this easier to configure
    if event is InputEventMouseButton or event is InputEventKey:
        if collided.try_click(event, owner):
            get_tree().get_root().set_input_as_handled()
