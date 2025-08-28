class_name PlayerRayCast3D extends RayCast3D
## When an input event is received, pipes input to the first `ClickTrigger` node
## that is colliding with this raycast


func _input(event: InputEvent) -> void:
    var collided := get_collider()
    if not collided or not collided is ClickTrigger:
        return

    # Limit interaction to mouse buttons for now, can remove this when input consumption is fixed
    if event is InputEventMouseButton:
        collided.on_click(event, owner)
