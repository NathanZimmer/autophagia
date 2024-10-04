extends Node3D

@export var activated_mat: StandardMaterial3D

var door: Node3D
var trigger_0: Area3D
var trigger_1: Area3D
var lights: Array[Node]

var trigger_0_activated: bool = false
var trigger_1_activated: bool = false
var counter: int = 0

func _ready():
	door = $WoodDoor
	trigger_0 = $Trigger0
	trigger_1 = $Trigger1
	var light = $Lights
	lights = light.find_children('', 'MeshInstance3D')

	trigger_0.connect('body_entered', _test.bind(trigger_0))
	trigger_1.connect('body_entered', _test.bind(trigger_1))

func _test(body, trigger):
	if not body is CharacterBody3D or counter > 2:
		return

	if trigger == trigger_0:
		trigger_0_activated = !trigger_0_activated
	else:
		trigger_1_activated = !trigger_1_activated

	if not (trigger_0_activated and trigger_1_activated):
		return

	trigger_0_activated = false
	trigger_1_activated = false

	lights[counter].material_override = activated_mat
	# TODO: Set door handle color from red, to orange, to gray
	counter += 1

	if counter >= 3:
		# TODO: call door open function
		print('Door opened')