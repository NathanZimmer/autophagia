extends CheckBox
## TODO


func _ready() -> void:
    var player_settings := Settings.player_settings
    toggled.connect(
        func(toggled_on: bool) -> void:
            player_settings.mouse_inverted = toggled_on
            ResourceSaver.save(player_settings)
    )
    button_pressed = player_settings.mouse_inverted
