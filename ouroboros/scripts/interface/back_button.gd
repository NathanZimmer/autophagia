extends Button


func _ready():
	pressed.connect(Globals.close_menu.emit)