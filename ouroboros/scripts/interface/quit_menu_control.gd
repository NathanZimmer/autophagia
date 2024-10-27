extends Control

@export var main_menu_scene_path: String

@onready var main_menu_button = $MainMenuButton
@onready var desktop_botton = $DesktopButton


func _ready() -> void:
	main_menu_button.pressed.connect(_quit_to_menu)
	desktop_botton.pressed.connect(_quit_game)


func _quit_to_menu() -> void:
	get_tree().change_scene_to_file(main_menu_scene_path)


func _quit_game() -> void:
	get_tree().quit()
