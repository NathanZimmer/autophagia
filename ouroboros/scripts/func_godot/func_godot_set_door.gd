@tool
extends Node3D

@export var func_godot_properties: Dictionary


func _func_godot_build_complete():
	global_rotation = func_godot_properties["rotation"] * PI / 180
