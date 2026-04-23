extends iMenuControl


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if (
        event is InputEventKey
        and (
            event.is_action_pressed(InputActions.Ui.INVENTORY)
            or event.is_action_pressed(InputActions.Ui.JOURNAL)
        )
    ):
        accept_event()
