extends MenuControl

const SCENE_LOADER_PATH: String = "res://ouroboros/scenes/main/scene_loader.tscn"

@export var main_scene_path: String

@onready var start_game_button: Button = $StartGameButton
@onready var quot_button: Button = $QuitButton


func _ready() -> void:
	super._ready()
	start_game_button.pressed.connect(_start_new_game)
	quot_button.pressed.connect(_quit_game)


func _start_new_game() -> void:
	Globals.scene_to_load_path = main_scene_path
	var scene_loader: PackedScene = load(SCENE_LOADER_PATH)
	get_tree().change_scene_to_packed(scene_loader)


func _quit_game() -> void:
	get_tree().quit()
