@tool
extends Node3D

@export var func_godot_properties: Dictionary


func _ready():
	var body: InteractableBody = get_child(0)
	body.locked = func_godot_properties["locked"]
	if func_godot_properties["open"]:
		body.set_open()

	if func_godot_properties["attach_signal"]:
		var close_signal = "close_and_lock_" + str(func_godot_properties["close_and_lock_signal"])
		if not Globals.has_user_signal(close_signal):
			Globals.add_user_signal(close_signal)

		Globals.connect(close_signal, body.close_and_lock)


func _func_godot_build_complete():
	global_rotation = func_godot_properties["rotation"] * PI / 180

	var body: InteractableBody = get_child(0)
	if func_godot_properties["open"]:
		body.set_open()