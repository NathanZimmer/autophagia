extends MenuControl


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.INVENTORY):
        menu_exited.emit()
        accept_event()
