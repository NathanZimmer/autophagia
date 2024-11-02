extends RayCast3D


@export var reticle: ColorRect
@export var default_color: Color
@export var hightlight_color: Color

var can_interact: bool = false


func _input(event):
	if not event is InputEventMouseButton:
		return

	if not (event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		return

	if can_interact:
		get_collider().interact.emit()



func _process(_delta):
	if not is_colliding():
		reticle.color = default_color
		can_interact = false
		return

	var target = get_collider()
	if target.is_in_group("interactable"):
		reticle.color = hightlight_color
		can_interact = true
