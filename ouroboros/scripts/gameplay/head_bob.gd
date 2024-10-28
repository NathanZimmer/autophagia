extends Node3D
## Handles player head-bobbing

signal bob_head
signal recenter

## The angle that the camera will rotate along the z-axis when head-bobbing
@export var bob_angle: float = 0.1
## The offset the camera will move to along the x-axis when head-bobbing. Head will bob from 0 to -x to 0 to x
@export var bob_offset_x: float = 0.01
## The offset the camera will move to along the y-axis when head-bobbing. Head will bob from 0 to y to 0 to y
@export var bob_offset_y: float = 0.01
## The time it will take for the camera to rotate from 0 degrees to `bob_angle` degrees
@export var bob_duration: float = 0.25

var position_y = position.y
# var rotation_tween: Tween
var position_tween: Tween
var return_tween: Tween

var bobbing: bool = true
var current_target: Vector2 = Vector2.ZERO


func _ready() -> void:
	recenter.connect(recenter_head)
	await head_bob()


func recenter_head() -> void:
	if position_tween == null or not position_tween.is_running():
		return

	bobbing = false

	# rotation_tween.stop()
	# rotation_tween.finished.emit()
	position_tween.stop()
	position_tween.finished.emit()

	return_tween = create_tween()
	return_tween.set_parallel()
	return_tween.tween_property(self, "position:x", 0, bob_duration * 0.5)
	return_tween.tween_property(self, "position:y", position_y, bob_duration * 0.5)
	return_tween.finished.connect(func(): bobbing = true)


func head_bob() -> void:
	while true:
		await bob_head
		if not bobbing:
			continue

		_create_tweens(bob_angle, -1 * bob_offset_x, bob_offset_y)
		await position_tween.finished
		if not bobbing:
			continue

		_create_tweens(0, 0, 0)
		await position_tween.finished
		await bob_head
		if not bobbing:
			continue

		_create_tweens(-1 * bob_angle, bob_offset_x, bob_offset_y)
		await position_tween.finished
		if not bobbing:
			continue

		_create_tweens(0, 0, 0)
		await position_tween.finished
		if not bobbing:
			continue


## Create two tweens to tween this object by `angle` and `offset` over `self.bob_duration`
func _create_tweens(_angle: float, offset_x: float, offset_y: float) -> void:
	# rotation_tween = create_tween()
	# rotation_tween.tween_property(self, "rotation:z", deg_to_rad(angle) * 0, bob_duration)
	position_tween = create_tween()
	position_tween.set_parallel()
	position_tween.tween_property(self, "position:x", offset_x, bob_duration).set_trans(Tween.TRANS_LINEAR)
	position_tween.tween_property(self, "position:y", position_y + offset_y, bob_duration).set_trans(Tween.TRANS_LINEAR)
	current_target = Vector2(offset_x, offset_y)
