class_name AreaRayCast3D extends RayCast3D
## RayCast3D that triggers the `body_entered` and `body_exited` signals of Area3D.

## Collided area from the last frame
var _area: Area3D = null


func _ready() -> void:
    collide_with_areas = true


func _physics_process(_delta) -> void:
    var collided := get_collider()
    if collided == null and _area == null:
        return

    # FIXME: Make this logic better
    if not collided is Area3D and not _area == null:
        _area.body_exited.emit(self)
        _area = null
        return
    if not collided is Area3D:
        return

    if _area == null:
        _area = collided
        _area.body_entered.emit(self)
    elif collided == null:
        _area.body_exited.emit(self)
        _area = null
    elif collided != _area:
        _area.body_exited.emit(self)
        _area = collided
        _area.body_entered.emit(self)
