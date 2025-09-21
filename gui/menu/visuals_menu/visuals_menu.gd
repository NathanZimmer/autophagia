extends MenuControl

@onready var _fov_spin_box: SpinBox = %FovSpinBox
@onready var _fps_spin_box: SpinBox = %FpsSpinBox
@onready var _vsynch_button: OptionButton = %VSynchOptionButton
@onready var _fullscreen_checkbox: CheckBox = %FullscreenCheckbox


func _ready() -> void:
    super._ready()

    var player_settings := Settings.player_settings
    var graphics_settings := Settings.graphics_settings

    _fov_spin_box.value_changed.connect(
        func(new_value: float) -> void:
            player_settings.fov = int(new_value)
            ResourceSaver.save(player_settings)
    )
    _fov_spin_box.value = player_settings.fov

    _fps_spin_box.value_changed.connect(
        func(new_value: float) -> void:
            graphics_settings.max_fps = int(new_value)
            ResourceSaver.save(graphics_settings)
    )
    _fps_spin_box.value = graphics_settings.max_fps

    _vsynch_button.item_selected.connect(
        func(index: int) -> void:
            graphics_settings.vsynch_mode = index as DisplayServer.VSyncMode
            ResourceSaver.save(graphics_settings)
    )
    _vsynch_button.selected = int(graphics_settings.vsynch_mode)

    _fullscreen_checkbox.toggled.connect(
        func(toggled_on: bool) -> void:
            graphics_settings.is_fullscreen = toggled_on
            ResourceSaver.save(graphics_settings)
    )
    _fullscreen_checkbox.button_pressed = graphics_settings.is_fullscreen

    # Need to keep in sync with actual value becuase it can be updated with the hotkey in gui.gd
    graphics_settings.is_fullscreen_changed.connect(
        func(is_fullscreen: bool) -> void:
            if _fullscreen_checkbox.button_pressed != is_fullscreen:
                _fullscreen_checkbox.button_pressed = is_fullscreen
    )
