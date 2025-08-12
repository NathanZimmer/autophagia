class_name AreaRayCast3D extends RayCast3D
## RayCast3D that triggers the `body_entered` and `body_exited` signals of Area3D.

## Collided area from the last frame
var _area: Area3D = null


func _ready():
    collide_with_areas = true


func _physics_process(_delta):
    var collided := get_collider()
    if not collided is Area3D:
        return

    if collided == null and _area == null:
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
