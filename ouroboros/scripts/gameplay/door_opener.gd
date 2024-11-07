@tool
class_name InteractableBody extends AnimatableBody3D

signal interact

const TRANS_MODE = Tween.TRANS_QUAD

@export var open: bool = false
@export var locked: bool = false
@export var move_duration: float = 0.5

var rotation_tween: Tween

@onready var door = $wood_door
@onready var collider = $CollisionShape3D
@onready var handle_anim_player = $HandleAnimationPlayer


func _ready():
	if open:
		set_open()

	if Engine.is_editor_hint():
		return

	interact.connect(open_close_door)


func open_close_door(override: bool = false):
	if locked and not override:
		handle_anim_player.play("handle_jiggle")
		return

	if open:
		rotation_tween = create_tween()
		rotation_tween.set_parallel()
		rotation_tween.tween_property(door, "rotation:y", 0, move_duration).set_trans(TRANS_MODE)
		rotation_tween.tween_property(collider, "rotation:y", 0, move_duration).set_trans(TRANS_MODE)
		open = false
		return

	rotation_tween = create_tween()
	rotation_tween.set_parallel()
	rotation_tween.tween_property(door, "rotation:y", deg_to_rad(-90), move_duration).set_trans(TRANS_MODE)
	rotation_tween.tween_property(collider, "rotation:y", deg_to_rad(-90), move_duration).set_trans(TRANS_MODE)
	open = true


func set_open() -> void:
	open = true
	door.rotation.y = deg_to_rad(-90)
	collider.rotation.y = deg_to_rad(-90)


func close_and_lock() -> void:
	if open:
		open_close_door()

	locked = true
