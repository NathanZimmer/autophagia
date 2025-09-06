extends SpinBox


func _ready() -> void:
    var player_settings := Settings.player_settings
    value_changed.connect(
        func(new_value: float) -> void:
            player_settings.fov = int(new_value)
            ResourceSaver.save(player_settings)
    )
    value = player_settings.fov
