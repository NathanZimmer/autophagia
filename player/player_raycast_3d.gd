class_name PlayerRayCast3D extends RayCast3D
## When an input event is received, pipes input to the first `ClickTrigger` node
## that is colliding with this raycast

## TODO
signal collision_changed(body: Object)

var _old_collider: Object


func _physics_process(_delta: float) -> void:
    var new_collider := get_collider()
    if _old_collider == new_collider:
        return
    collision_changed.emit(new_collider)
    _old_collider = new_collider


func _unhandled_input(event: InputEvent) -> void:
    var collided := get_collider()
    if not collided or not collided is ClickTrigger:
        return

    # TODO: Create constant or expose as @export to make this easier to configure
    if event is InputEventMouseButton or event is InputEventKey:
        if collided.try_click(event, owner):
            get_tree().get_root().set_input_as_handled()
