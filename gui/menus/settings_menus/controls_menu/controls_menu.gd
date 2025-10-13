extends MenuControl

@onready var _sensitivity_slider := %SensitivitySlider
@onready var _invert_mouse_checkbox := %InvertMouseCheckBox


func _ready() -> void:
    super._ready()

    _sensitivity_slider.slider_drag_ended.connect(
        func(value_changed: bool) -> void:
            if not value_changed:
                return
            Overrides.save_mouse_sensitivity(int(_sensitivity_slider.value))
    )
    _sensitivity_slider.spin_box_value_changed.connect(
        func(new_value: float) -> void: Overrides.save_mouse_sensitivity(int(new_value))
    )
    _sensitivity_slider.value = Overrides.load_mouse_sensitivity()

    _invert_mouse_checkbox.toggled.connect(
        func(toggled_on: bool) -> void: Overrides.save_mouse_inverted(toggled_on)
    )
    _invert_mouse_checkbox.button_pressed = Overrides.load_mouse_inverted()
