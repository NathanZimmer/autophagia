extends Area3D

@export var to_free: Array[Node3D]
@export var to_load: PackedScene


func _ready():
	connect('body_entered', _change_scene.bind())


func _change_scene(_body):
	if not _body is CharacterBody3D:
		return

	for node in to_free:
		node.queue_free()

	var loaded = to_load.instantiate()
	get_tree().get_root().add_child(loaded)
	queue_free()
