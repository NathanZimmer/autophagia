extends Control

@onready var desktop_botton = $DesktopButton
@onready var back_button = $BackButton

func _ready():
	desktop_botton.pressed.connect(_quit_game)
	back_button.pressed.connect(_back_button_pressed)

func _unhandled_input(event) -> void:
	if not visible:
		return

	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			hide()
			Globals.pause.emit()
			get_tree().get_root().set_input_as_handled()


func _back_button_pressed():
	hide()
	Globals.pause.emit()

func _quit_game():
	get_tree().quit()