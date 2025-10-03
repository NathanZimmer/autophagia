extends MenuControl

@onready var _fov_spin_box: SpinBox = %FovSpinBox
@onready var _fps_spin_box: SpinBox = %FpsSpinBox
@onready var _vsynch_button: OptionButton = %VSynchOptionButton
@onready var _fullscreen_checkbox: CheckBox = %FullscreenCheckbox


func _ready() -> void:
    super._ready()

    _fov_spin_box.value_changed.connect(
        func(new_value: float) -> void: Overrides.save_fov(int(new_value))
    )
    _fov_spin_box.value = Overrides.load_fov()

    _fps_spin_box.value_changed.connect(
        func(new_value: float) -> void: Overrides.save_max_fps(int(new_value))
    )
    _fps_spin_box.value = Overrides.load_max_fps()

    _vsynch_button.item_selected.connect(
        func(index: int) -> void: Overrides.save_vsync_mode(index as DisplayServer.VSyncMode)
    )
    _vsynch_button.selected = int(Overrides.load_vsync_mode())

    _fullscreen_checkbox.toggled.connect(
        func(toggled_on: bool) -> void: Overrides.save_fullscreen(toggled_on)
    )
    _fullscreen_checkbox.button_pressed = Overrides.load_fullscreen()

    # Need to keep in sync with actual value becuase it can be updated with the hotkey in gui.gd
    Overrides.fullscreen_changed.connect(
        func(is_fullscreen: bool) -> void:
            if _fullscreen_checkbox.button_pressed != is_fullscreen:
                _fullscreen_checkbox.button_pressed = is_fullscreen
    )
