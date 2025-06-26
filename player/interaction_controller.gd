extends RayCast3D

@export var reticle: ColorRect
@export var default_color: Color
@export var hightlight_color: Color

var can_interact := false
var target


func _input(event):
    if not event is InputEventMouseButton:
        return

    if not (event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
        return

    if can_interact:
        target.interact.emit()


func _process(_delta):
    if not is_colliding():
        reticle.color = default_color
        can_interact = false
        return

    target = get_collider()

    if target.is_in_group("portal"):
        var portal_container: PortalContainer = target.get_parent()
        target = portal_container.cast_ray_through_portal(self, target)

        if target == null:
            reticle.color = default_color
            can_interact = false
            return

    if target.is_in_group("interactable"):
        reticle.color = hightlight_color
        can_interact = true
        return

    reticle.color = default_color
    can_interact = false
