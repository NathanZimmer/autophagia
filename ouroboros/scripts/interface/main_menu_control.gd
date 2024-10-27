extends MenuControl


@export var main_scene_path: String

@onready var start_game_button: Button = $StartGameButton
@onready var quot_button: Button = $QuitButton


func _ready() -> void:
	super._ready()
	start_game_button.pressed.connect(_start_new_game)
	quot_button.pressed.connect(_quit_game)

func _start_new_game() -> void:
	Globals.unpause.emit()
	get_tree().change_scene_to_file(main_scene_path)


func _quit_game() -> void:
	get_tree().quit()
