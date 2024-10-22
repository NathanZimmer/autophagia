extends Control


@onready var res_scale_slider_box_pair: Control = $ResScaleSliderBoxPair
@onready var fov_slider_box_pair: Control = $FOVSliderBoxPair
@onready var msaa_option_button: OptionButton = $MSAAOptionButton
@onready var fullscreen_check_box: CheckBox = $FullscreenCheckBox
@onready var apply_changes_button: Button = $ApplyChangesButton


func _ready() -> void:
	apply_changes_button.pressed.connect(_apply_changes)

	# Keep the button up to date with fullscreen mode because it can be changed by the hotkey
	fullscreen_check_box.button_pressed = (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	Globals.toggle_fullscreen.connect(_set_fullscreen)

	# Set UI values based on current game settings
	fov_slider_box_pair.value = 90
	res_scale_slider_box_pair.value = get_viewport().scaling_3d_scale * 100
	msaa_option_button.selected = get_viewport().msaa_3d


func _set_fullscreen(is_fullscreen: bool) -> void:
	fullscreen_check_box.button_pressed = is_fullscreen
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)


func _apply_changes() -> void:
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_check_box.button_pressed
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)

	get_viewport().msaa_3d = msaa_option_button.selected as Viewport.MSAA
	Globals.change_resolution_scale.emit(res_scale_slider_box_pair.value)
	Globals.change_fov.emit(fov_slider_box_pair.value)
	get_viewport().scaling_3d_scale = res_scale_slider_box_pair.value / 100
