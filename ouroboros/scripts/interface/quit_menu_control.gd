extends Control

var pause_control: PauseControl

@onready var desktop_botton = $DesktopButton
@onready var back_button = $BackButton


func _ready() -> void:
	pause_control = get_parent()

	desktop_botton.pressed.connect(_quit_game)
	back_button.pressed.connect(pause_control.close_menu)


func _quit_game() -> void:
	get_tree().quit()
