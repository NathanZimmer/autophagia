extends Control
## Handles menu and viewport related hotkeys, captures mouse, and connects to root pause menu

## Root pause menu
@onready var pause_menu: MenuController = %PauseMenu


func _ready() -> void:
    pause_menu.menu_exited.connect(_unpause)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.is_action_pressed(InputActions.UI.CANCEL):
            _pause()
            accept_event()

        elif event.is_action_pressed(InputActions.UI.FULLSCREEN):
            _toggle_fullscreen()
            accept_event()


## TODO
func _pause() -> void:
    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    pause_menu.show()


## TODO
func _unpause() -> void:
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    pause_menu.hide()


## Toggle window mode between `WINDOW_MODE_FULLSCREEN` and `WINDOW_MODE_WINDOWED`
func _toggle_fullscreen() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
