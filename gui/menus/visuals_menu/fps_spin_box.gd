extends SpinBox
## TODO


func _ready() -> void:
    var graphics_settings := Settings.graphics_settings
    value_changed.connect(
        func(new_value: float) -> void:
            graphics_settings.max_fps = int(new_value)
            ResourceSaver.save(graphics_settings)
    )
    value = graphics_settings.max_fps
