@tool
extends Node3D

@export var func_godot_properties: Dictionary


func _ready():
	if Engine.is_editor_hint():
		return

	var body: InteractableBody = get_child(0)
	body.locked = func_godot_properties["locked"]


func _func_godot_build_complete():
	global_rotation = func_godot_properties["rotation"] * PI / 180

