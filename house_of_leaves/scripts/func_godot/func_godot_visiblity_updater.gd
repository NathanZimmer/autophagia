@tool
extends Node3D

@export var func_godot_properties: Dictionary

func _ready():
	if Engine.is_editor_hint():
		return


	var signal_hide = 'hide_' + str(func_godot_properties['signal_id'])
	if not Globals.has_user_signal(signal_hide):
		Globals.add_user_signal(signal_hide)

	Globals.connect(signal_hide, hide)

	var signal_show = 'show_' + str(func_godot_properties['signal_id'])
	if not Globals.has_user_signal(signal_show):
		Globals.add_user_signal(signal_show)

	Globals.connect(signal_show, show)

func _func_godot_build_complete():
	if not func_godot_properties['visible']:
		hide()
