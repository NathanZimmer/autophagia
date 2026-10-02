class_name PlayerCamera extends Camera3D
## TODO

## TODO
signal transform_changed(global_transform: Transform3D)


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSFORM_CHANGED:
        transform_changed.emit(global_transform)
