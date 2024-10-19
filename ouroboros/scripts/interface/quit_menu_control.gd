extends Control

var pause_control: PauseControl

@onready var desktop_botton = $DesktopButton


func _ready() -> void:
	pause_control = get_parent()

	desktop_botton.pressed.connect(_quit_game)


func _quit_game() -> void:
	get_tree().quit()
