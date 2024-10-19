extends Node
## Stores all global variables, signals, and hotkeys

signal pause
signal swap_menu

## Sets certain values to their default
func _ready():
    process_mode = PROCESS_MODE_ALWAYS
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    # DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    pass


# Handle global hotkeys
func _unhandled_input(event) -> void:
    if event is InputEventKey:
        if event.is_action_pressed("fullscreen"):
            DisplayServer.window_set_mode(
				(
					DisplayServer.WINDOW_MODE_WINDOWED
					if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
					else DisplayServer.WINDOW_MODE_FULLSCREEN
				)
			)
            get_tree().get_root().set_input_as_handled()
