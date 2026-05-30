extends iMenuControl


func _shortcut_input(event: InputEvent) -> void:
    if not (event is InputEventKey or event is InputEventMouseButton):
        return

    if (
        event.is_action_pressed(InputActions.Ui.INVENTORY)
        or event.is_action_pressed(InputActions.Ui.JOURNAL)
    ):
        accept_event()
    else:
        super._shortcut_input(event)
