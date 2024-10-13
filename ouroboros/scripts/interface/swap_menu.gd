extends Button

@export var to_show: Control


func _ready():
	pressed.connect(_on_press)


func _on_press():
	get_parent().hide()
	to_show.show()
