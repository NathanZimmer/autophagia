extends Control


@onready var resolution_slider: Slider = $ResolutionSlider
@onready var resolution_spin_box: SpinBox = $ResolutionSpinBox
@onready var msaa_option_button: OptionButton = $MSAAOptionButton
@onready var fullscreen_check_box: CheckBox = $FullscreenCheckBox
@onready var apply_changes_button: Button = $ApplyChangesButton


func _ready():
	resolution_slider.value_changed.connect(_update_resolution_scale_value)
	resolution_spin_box.value_changed.connect(_update_resolution_scale_value)
	apply_changes_button.pressed.connect(_apply_changes)

	# Keep the button up to date with fullscreen mode because it can be changed by the hotkey
	fullscreen_check_box.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	Globals.toggle_fullscreen.connect(_set_fullscreen)

	# Set UI values based on current game settings
	msaa_option_button.selected = get_viewport().msaa_3d
	_update_resolution_scale_value(get_viewport().scaling_3d_scale * 100)


func _set_fullscreen(is_fullscreen: bool) -> void:
	fullscreen_check_box.button_pressed = is_fullscreen
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


## If the `Slider` or `SpinBox` is updated, update the other to match.
func _update_resolution_scale_value(resolution_scale: float) -> void:
	resolution_slider.value = int(resolution_scale)
	resolution_spin_box.value = int(resolution_scale)


func _apply_changes() -> void:
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check_box.button_pressed
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)

	get_viewport().msaa_3d = msaa_option_button.selected as Viewport.MSAA
	Globals.change_resolution_scale.emit(resolution_slider.value)
	get_viewport().scaling_3d_scale = resolution_slider.value / 100
