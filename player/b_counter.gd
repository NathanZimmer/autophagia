extends Label

var b_press_time_elapsed: float = 0


func _unhandled_input(event) -> void:
	if not event is InputEventKey:
		return

	if event.is_action_pressed("player_b"):
		b_press_time_elapsed = 0


func _process(delta):
	b_press_time_elapsed += delta
	text = ('Seconds since the "B" key has been pressed: %d' % [int(b_press_time_elapsed)])
