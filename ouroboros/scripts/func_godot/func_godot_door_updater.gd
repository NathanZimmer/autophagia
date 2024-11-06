@tool
extends Node3D

@export var func_godot_properties: Dictionary


func _ready():
	var body: InteractableBody = get_child(0)
	body.locked = func_godot_properties["locked"]
	if func_godot_properties["open"]:
		body.set_open()


func _func_godot_build_complete():
	global_rotation = func_godot_properties["rotation"] * PI / 180

	var body: InteractableBody = get_child(0)
	if func_godot_properties["open"]:
		body.set_open()