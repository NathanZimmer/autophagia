@tool
extends HSliderSpinBox
## TODO


func _ready() -> void:
    super._ready()
    if Engine.is_editor_hint():
        return

    var player_settings := Settings.player_settings
    drag_ended.connect(
        func(new_value: bool) -> void:
            if not new_value:
                return
            player_settings.mouse_sensitivity = int(value)
            ResourceSaver.save(player_settings)
    )
    value = player_settings.mouse_sensitivity
