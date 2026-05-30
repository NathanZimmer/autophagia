extends Control
## Handle input needed for the main menu


func _shortcut_input(event: InputEvent) -> void:
    if (
        (event is InputEventKey or event is InputEventMouseButton)
        and event.is_action_pressed(InputActions.Ui.FULLSCREEN)
    ):
        Overrides.save_fullscreen(!Overrides.load_fullscreen())
        accept_event()
