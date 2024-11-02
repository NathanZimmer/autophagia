extends AnimatableBody3D


signal interact

@export var locked: bool = false
@export var move_duration: float = 0.5

@onready var door = $wood_door
@onready var collider = $CollisionShape3D
@onready var handle_anim_player = $HandleAnimationPlayer

var open: bool = false
var rotation_tween: Tween

func _ready():
	interact.connect(_open_close_door)


func _open_close_door():
	if locked:
		handle_anim_player.play('handle_jiggle')
		return

	if open:
		rotation_tween = create_tween()
		rotation_tween.set_parallel()
		rotation_tween.tween_property(door, "rotation:y", 0, move_duration)
		rotation_tween.tween_property(collider, "rotation:y", 0, move_duration)
		open = false
		return

	rotation_tween = create_tween()
	rotation_tween.set_parallel()
	rotation_tween.tween_property(door, "rotation:y", deg_to_rad(-90), move_duration)
	rotation_tween.tween_property(collider, "rotation:y", deg_to_rad(-90), move_duration)
	open = true