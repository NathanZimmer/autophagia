class_name AreaRayCast3D extends RayCast3D
## RayCast3D that triggers the `body_entered` and `body_exited` signals of Area3D.
# FIXME: The raycast probably shouldn't give itself as the body, this isn't how any other
# collision works in Godot.

## Collided object from the last frame
var col_object: CollisionObject3D = null


func _ready() -> void:
    collide_with_areas = true


func _physics_process(_delta) -> void:
    var collided := get_collider()
    if collided == null and col_object == null:
        return

    if not collided is Area3D:
        if not col_object == null:
            col_object.body_exited.emit(self)
            col_object = null
        return

    if col_object == null:
        col_object = collided
        col_object.body_entered.emit(self)
    elif collided == null:
        col_object.body_exited.emit(self)
        col_object = null
    elif collided != col_object:
        col_object.body_exited.emit(self)
        col_object = collided
        col_object.body_entered.emit(self)
