@tool
extends Node3D

@export var func_godot_properties: Dictionary

func _ready():
	if Engine.is_editor_hint():
		return


	var signal_hide = 'hide_' + str(func_godot_properties['signal_id'])
	if not Globals.has_user_signal(signal_hide):
		Globals.add_user_signal(signal_hide)

	Globals.connect(signal_hide, hide_brush)

	var signal_show = 'show_' + str(func_godot_properties['signal_id'])
	if not Globals.has_user_signal(signal_show):
		Globals.add_user_signal(signal_show)

	Globals.connect(signal_show, show_brush)

func _func_godot_build_complete():
	if not func_godot_properties['visible']:
		hide_brush()

func hide_brush():
	var collider: CollisionShape3D = find_children('', 'CollisionShape3D')[0]
	collider.set_deferred('disabled', true)
	hide()

func show_brush():
	show()
	var collider: CollisionShape3D = find_children('', 'CollisionShape3D')[0]
	collider.set_deferred('disabled', false)
