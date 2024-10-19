extends MenuControl

@onready var return_button = $ReturnButton
@onready var quit_button = $QuitButton


func _ready() -> void:
	super._ready()
	return_button.pressed.connect(pause_control.close_menu)
