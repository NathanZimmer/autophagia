extends TextureRect

# @export var movement_factor: Vector2
@export var duration: float


func _ready():
	await _move()


func _move():
	var movement_tween: Tween
	while true:
		movement_tween = create_tween()
		movement_tween.set_parallel()
		movement_tween.tween_property(self, "position:y", -720, duration)
		await movement_tween.finished
		position.y = 0
