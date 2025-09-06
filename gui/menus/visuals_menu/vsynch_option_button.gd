extends OptionButton
## TODO


func _ready() -> void:
    var graphics_settings := Settings.graphics_settings
    item_selected.connect(
        func(index: int) -> void:
            graphics_settings.vsynch_mode = index as DisplayServer.VSyncMode
            ResourceSaver.save(graphics_settings)
    )
    selected = int(graphics_settings.vsynch_mode)
