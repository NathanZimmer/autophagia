class_name Player extends CharacterBody3D
## Handles player movement, jumping, and gravity

@export_group("Camera settings")
@export_range(1, 100, 1) var mouse_sensitivity := 50
@export var max_x_rotation := 89.0
@export var min_x_rotation := -89.0

@export_group("Player movement settings")
@export var move_speed := 3.0
## The upward velocity of a jump
@export var jump_velocity := 4.5
## The percentage of the players walk velocity that caries into a jump
@export var xz_jump_velocity := 0.75
## The percentage of the players walk velocity to apply when airborne
@export var xz_air_velocity := 0.01

@export_group("Dev controls")
@export var override_up_dir_on_ready := true
@export var dev_controls_enabled := true
@export var min_speed := 0.1
@export var max_speed := 10.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed_mod := 1.0  # Modifier to player speed that can be adjusted with mouse wheel
var flying := false
var collider: CollisionShape3D
var camera: Camera3D
var mouse_inverted := false


func _ready() -> void:
    Globals.change_mouse_sensitivity.connect(_change_sensitivity)
    Globals.change_mouse_invertion.connect(_set_mouse_invertion)
    Globals.change_fov.connect(_change_fov)

    camera = find_children("", "Camera3D")[0]
    collider = find_children("", "CollisionShape3D")[0]
    # Input.set_use_accumulated_input(false)

    if override_up_dir_on_ready:
        up_direction = global_basis.y


func _input(event) -> void:
    if event is InputEventMouseMotion:
        _rotate_cam(event)

    if event is InputEventKey:
        if event.is_action_pressed("player_flight_toggle") and dev_controls_enabled:
            flying = not flying
        elif event.is_action_pressed("player_toggle_collision") and dev_controls_enabled:
            collider.disabled = not collider.disabled

    if event is InputEventMouseButton:
        var mw_input_scale: float = 0.1
        if event.is_action_pressed("mw_down") and dev_controls_enabled:
            speed_mod -= mw_input_scale
            speed_mod = speed_mod if speed_mod > min_speed else min_speed
        elif event.is_action_pressed("mw_up") and dev_controls_enabled:
            speed_mod += mw_input_scale
            speed_mod = speed_mod if speed_mod < max_speed else max_speed


func _physics_process(delta: float) -> void:
    _walk_and_jump(delta)
    move_and_slide()
    orthonormalize()


# FIXME: Sometimes the player cannot jump, this is probaly from the basis changing
## Handle player input for walking and jumping using the player_* input actions
func _walk_and_jump(delta: float):
    var xz_input_dir := Input.get_vector(
        "player_left", "player_right", "player_forward", "player_back"
    )

    var right := global_basis.x * xz_input_dir.x
    var forward := global_basis.z * xz_input_dir.y
    var xz_velocity = (right + forward).normalized() * move_speed * speed_mod

    # Need to handle jumping, falling, and flying separately from xz movement
    var y_velocity: Vector3
    if not flying:
        y_velocity = velocity.project(global_basis.y)
        if not is_on_floor():
            y_velocity -= global_basis.y * gravity * delta
        if Input.is_action_just_pressed("player_up") and is_on_floor():
            y_velocity += jump_velocity * global_basis.y
    else:
        var y_input_dir = Input.get_axis("player_down", "player_up")
        var up = global_basis.y * y_input_dir
        y_velocity = up * move_speed * speed_mod

    velocity = xz_velocity + y_velocity
    if not flying:
        camera.bob_head.emit()
    if not xz_velocity:
        camera.recenter.emit()


## Handle mouse input for camera rotation [br]
## `event`: mouse movement to be used to rotate the camera.
func _rotate_cam(event: InputEventMouseMotion) -> void:
    var viewport_transform: Transform2D = get_tree().root.get_final_transform()
    var motion: Vector2 = event.xformed_by(viewport_transform).relative
    var degrees_per_unit: float = 0.001

    motion *= mouse_sensitivity
    motion *= degrees_per_unit

    rotate_object_local(Vector3.DOWN, deg_to_rad(motion.x))
    camera.rotate_object_local(
        Vector3.LEFT, deg_to_rad(-1 * motion.y if mouse_inverted else motion.y)
    )
    camera.rotation.x = clamp(
        camera.rotation.x, deg_to_rad(min_x_rotation), deg_to_rad(max_x_rotation)
    )
    camera.orthonormalize()


func _change_sensitivity(sensitivity: int) -> void:
    mouse_sensitivity = sensitivity


func _set_mouse_invertion(inverted: bool) -> void:
    mouse_inverted = inverted


func _change_fov(fov: int) -> void:
    camera.fov = fov
