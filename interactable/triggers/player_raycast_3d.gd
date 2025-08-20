class_name PlayerRayCast3D extends RayCast3D
## TODO

var _collided: CollisionObject3D


func _physics_process(_delta) -> void:
    _collided = get_collider()


func _input(event: InputEvent):
    if _collided == null or not _collided is ClickTrigger:
        return

    # Limit interaction to mouse buttons for now
    if event is InputEventMouseButton:
        _collided.on_click(event, owner)
