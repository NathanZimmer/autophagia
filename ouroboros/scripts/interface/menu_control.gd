@tool
class_name MenuControl extends Control
## Contains a dictionary for swapping between menus. Must be a child of a `PauseControl` object.

## Reference to parent
var pause_control: PauseControl

## `Dictionary{Button, Control}` Links `Buttons` to the `Controls` that they open
@export var swap_list: Dictionary


func _ready():
	if Engine.is_editor_hint():
		return

	pause_control = get_parent()

	# Connecting menu swapping buttons
	for button in swap_list:
		var control = swap_list[button]
		get_node(button).pressed.connect(pause_control.open_menu.bind(get_node(control)))

func _get_configuration_warnings():
	if not get_parent() is PauseControl:
		return ["The parent of this object must be a `PauseControl`"]