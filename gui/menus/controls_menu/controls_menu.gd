extends MenuController
# FIXME: Make return button clickable again

@onready var _sensitivity_slider := %SensitivitySlider
@onready var _invert_mouse_checkbox := %InvertMouseCheckBox


func _ready() -> void:
	var player_settings := Settings.player_settings
	
	_sensitivity_slider.slider_drag_ended.connect(
		func(value_changed: bool) -> void:
			if not value_changed:
				return
			player_settings.mouse_sensitivity = int(_sensitivity_slider.value)
			ResourceSaver.save(player_settings)
	)
	_sensitivity_slider.spin_box_value_changed.connect(
		func(new_value: float) -> void:
			player_settings.mouse_sensitivity = int(new_value)
			ResourceSaver.save(player_settings)
	)
	_sensitivity_slider.value = player_settings.mouse_sensitivity

	_invert_mouse_checkbox.toggled.connect(
		func(toggled_on: bool) -> void:
			player_settings.mouse_inverted = toggled_on
			ResourceSaver.save(player_settings)
	)
	_invert_mouse_checkbox.button_pressed = player_settings.mouse_inverted
