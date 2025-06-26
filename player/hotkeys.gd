extends Node
## Handles hotkeys during gameplay


func _unhandled_input(event) -> void:
	if event is InputEvent:
		if event.is_action_pressed("ui_cancel"):
			get_tree().paused = true
			Globals.pause.emit()
			get_tree().get_root().set_input_as_handled()
