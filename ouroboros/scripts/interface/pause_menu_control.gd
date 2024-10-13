extends Control


@onready var return_button = $ReturnButton

func _ready() -> void:
	Globals.pause.connect(start_pause)
	return_button.pressed.connect(stop_pause)


func _unhandled_input(event) -> void:
	if not visible:
		return

	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			stop_pause()
			get_tree().get_root().set_input_as_handled()



## Starts a pause state: shows menu and frees mouse
func start_pause():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()


## Terminates the pause state: emits a global unpause and captures mouse
func stop_pause():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
	get_tree().paused = false