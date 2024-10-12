extends Node3D
## Handles player head-bobbing

signal bob_head

## The angle that the camera will rotate along the z-axis when head-bobbing
@export var bob_angle: float = 0.25
## The offset the camera will move to along the x-axis when head-bobbing
@export var bob_offset: float = 0.01
## The time it will take for the camera to rotate from 0 degrees to `bob_angle` degrees
@export var bob_duration: float = 0.3


func _ready() -> void:
    await head_bob()


func head_bob() -> void:
    var rotation_tween: Tween
    while true:
        await bob_head
        rotation_tween = _create_rotation_tween(bob_angle, -1 * bob_offset)
        rotation_tween.play()
        await rotation_tween.finished

        rotation_tween = _create_rotation_tween(0, 0)
        rotation_tween.play()
        await rotation_tween.finished
        await bob_head

        rotation_tween = _create_rotation_tween(-1 * bob_angle, bob_offset)
        rotation_tween.play()
        await rotation_tween.finished

        rotation_tween = _create_rotation_tween(0, 0)
        rotation_tween.play()
        await rotation_tween.finished


func _create_rotation_tween(angle: float, offset: float) -> Tween:
    var rotation_tween: Tween = create_tween()
    rotation_tween.tween_property(self, "rotation:z", deg_to_rad(angle), bob_duration).set_trans(Tween.TRANS_QUAD)
    var movement_tween: Tween = create_tween()
    movement_tween.tween_property(self, "position:x", offset, bob_duration).set_trans(Tween.TRANS_LINEAR)

    return rotation_tween