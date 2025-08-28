class_name Player extends CharacterBody3D
## Handles player movement, jumping, and gravity

const TERMINAL_VELOCITY := 50.0

@export_group("Camera settings")
@export_range(1, 100, 1) var _mouse_sensitivity := 50
@export var _min_x_rotation := -89.0
@export var _max_x_rotation := 89.0

@export_group("Player movement settings")
@export var _move_speed := 3.0
## The upward velocity of a jump
@export var _jump_velocity := 4.5

@export_group("Dev controls")
@export var _dev_controls_enabled := true
@export var _override_up_dir_on_ready := true
@export var _min_speed := 0.1
@export var _max_speed := 10.0
@export var _capture_input := false

var camera: Camera3D:
    get:
        return _camera
    set(value):
        push_warning("camera is a read-only property")

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _speed_mod := 1.0  # Modifier to player speed that can be adjusted with mouse wheel
var _flying := false
var _collider: CollisionShape3D
var _camera: Camera3D
var _mouse_inverted := false


func _ready() -> void:
    _camera = find_children("", "Camera3D")[0]
    _collider = find_children("", "CollisionShape3D")[0]
    # Input.set_use_accumulated_input(false)

    if _override_up_dir_on_ready:
        up_direction = global_basis.y
    if _capture_input:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# FIXME: Figure out what is consuming all inputs down the tree, fix it, and update
# this to _unhandled_input
func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        _rotate_cam(event)
    elif event is InputEventKey:
        if event.is_action_pressed(PlayerInput.PLAYER_FLIGHT_TOGGLE) and _dev_controls_enabled:
            _flying = !_flying
        elif event.is_action_pressed(PlayerInput.PLAYER_COLLISION_TOGGLE) and _dev_controls_enabled:
            _collider.disabled = not _collider.disabled
    elif event is InputEventMouseButton:
        var mw_input_scale: float = 0.1
        if event.is_action_pressed("mw_down") and _dev_controls_enabled:
            _speed_mod -= mw_input_scale
            _speed_mod = _speed_mod if _speed_mod > _min_speed else _min_speed
        elif event.is_action_pressed("mw_up") and _dev_controls_enabled:
            _speed_mod += mw_input_scale
            _speed_mod = _speed_mod if _speed_mod < _max_speed else _max_speed


func _physics_process(delta: float) -> void:
    _walk_and_jump(delta)
    move_and_slide()
    orthonormalize()


# FIXME: Sometimes the player cannot jump, this is probaly from the basis changing
## Handle player input for walking and jumping using the player_* input actions
func _walk_and_jump(delta: float) -> void:
    var xz_input_dir := Input.get_vector(
        PlayerInput.PLAYER_LEFT,
        PlayerInput.PLAYER_RIGHT,
        PlayerInput.PLAYER_FORWARD,
        PlayerInput.PLAYER_BACK
    )

    var right := global_basis.x * xz_input_dir.x
    var forward := global_basis.z * xz_input_dir.y
    var xz_velocity := (right + forward).normalized() * _move_speed * _speed_mod

    # Need to handle jumping, falling, and _flying separately from xz movement
    var y_velocity: Vector3
    if not _flying:
        y_velocity = velocity.project(global_basis.y)
        if not is_on_floor():
            y_velocity -= global_basis.y * _gravity * delta
            if y_velocity.length() >= TERMINAL_VELOCITY:
                y_velocity = global_basis.y * -TERMINAL_VELOCITY
        if Input.is_action_just_pressed(PlayerInput.PLAYER_UP) and is_on_floor():
            y_velocity += _jump_velocity * global_basis.y
    else:
        var y_input_dir := Input.get_axis(PlayerInput.PLAYER_DOWN, PlayerInput.PLAYER_UP)
        var up := global_basis.y * y_input_dir
        y_velocity = up * _move_speed * _speed_mod

    velocity = xz_velocity + y_velocity


## Handle mouse input for camera rotation [br]
## ## Parameters [br]
## `event`: mouse movement to be used to rotate the camera.
func _rotate_cam(event: InputEventMouseMotion) -> void:
    var viewport_transform: Transform2D = get_tree().root.get_final_transform()
    var motion: Vector2 = event.xformed_by(viewport_transform).relative
    var degrees_per_unit: float = 0.001

    motion *= _mouse_sensitivity * degrees_per_unit

    rotate_object_local(Vector3.DOWN, deg_to_rad(motion.x))
    _camera.rotate_object_local(
        Vector3.LEFT, deg_to_rad(-1 * motion.y if _mouse_inverted else motion.y)
    )
    _camera.rotation.x = clamp(
        _camera.rotation.x, deg_to_rad(_min_x_rotation), deg_to_rad(_max_x_rotation)
    )
    _camera.orthonormalize()
