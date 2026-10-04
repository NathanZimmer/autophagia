class_name TrackedCamera extends Camera3D
## Camera That emits `transform_changed` whenever its transform changes

## Emitted when transform changes hit `_notification` function. Emits current global transform
signal transform_changed(global_transform: Transform3D)


func _notification(what: int) -> void:
    if what == NOTIFICATION_TRANSFORM_CHANGED:
        transform_changed.emit(global_transform)
