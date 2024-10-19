extends Control

@onready var desktop_botton = $DesktopButton
@onready var back_button = $BackButton

var pause_control: PauseControl


func _ready():
	pause_control = get_parent()

	desktop_botton.pressed.connect(_quit_game)
	back_button.pressed.connect(pause_control.close_menu)


func _quit_game():
	get_tree().quit()