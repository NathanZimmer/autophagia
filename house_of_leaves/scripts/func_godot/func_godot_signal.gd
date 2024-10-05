@tool
extends Area3D

@export var func_godot_properties: Dictionary


func _ready():
	connect("body_entered", _emit_signal.bind())


func _emit_signal(body):
	if not body is CharacterBody3D:
		return

	Globals.emit_signal(func_godot_properties["signal"])
