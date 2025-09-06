extends CheckBox
## TODO


func _ready() -> void:
    var graphics_settings := Settings.graphics_settings
    toggled.connect(
        func(toggled_on: bool) -> void:
            graphics_settings.is_fullscreen = toggled_on
            ResourceSaver.save(graphics_settings)
    )
    button_pressed = graphics_settings.is_fullscreen

    # Need to keep in sync with actual value becuase it can be updated with the hotkey in gui.gd
    graphics_settings.is_fullscreen_updated.connect(
        func(is_fullscreen: bool) -> void:
            if button_pressed != is_fullscreen:
                button_pressed = is_fullscreen
    )
