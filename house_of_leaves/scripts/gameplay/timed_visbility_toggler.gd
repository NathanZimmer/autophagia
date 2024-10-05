extends Node3D

## How long the object stays hidden for
@export var hide_duration: float = 0.5
## How long the object is visible for
@export var show_duration: float = 0.5

var wait_start_time: float = 0
var elapsed_time: float = 0


func _process(delta):
	elapsed_time += delta

	if visible and show_duration - elapsed_time <= 0:
		hide()
		elapsed_time = 0
	elif not visible and hide_duration - elapsed_time <= 0:
		show()
		elapsed_time = 0
