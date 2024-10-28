extends TextureRect

## Seconds it takes to make a full rotation
@export var duration: float = 1


func _ready() -> void:
	await _spin()


func _spin() -> void:
	var rotation_tween: Tween = create_tween()
	rotation_tween.tween_property(self, "rotation", -2 * PI, duration)
	while true:
		rotation_tween.play()
		await rotation_tween.finished
		rotation_tween.stop()
		rotation = 0
