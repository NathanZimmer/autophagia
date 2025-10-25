extends Control
## Handle input needed for the main menu


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.FULLSCREEN):
        _toggle_fullscreen()
        accept_event()


## Toggle window mode between `WINDOW_MODE_FULLSCREEN` and `WINDOW_MODE_WINDOWED`
func _toggle_fullscreen() -> void:
    var fullscreen := Overrides.load_fullscreen()
    Overrides.save_fullscreen(!fullscreen)
