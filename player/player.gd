extends CharacterBody3D
## Handles player movement, jumping, and gravity

const TERMINAL_VELOCITY := 50.0
## If true, this script will control mouse capture mode with "ui_cancel" input.
## Use for scenes where the gui scripts aren't loaded and input isn't captured.
const DEBUG_CAPTURE_MOUSE := false

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

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if DEBUG_CAPTURE_MOUSE and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
            return

        _rotate_cam(event)
        get_tree().get_root().set_input_as_handled()

    elif event is InputEventKey:
        if DEBUG_CAPTURE_MOUSE and event.is_action_pressed("ui_cancel"):
            if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
                Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
            else:
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

        elif event.is_action_pressed(InputActions.Player.FLIGHT_TOGGLE) and _dev_controls_enabled:
            _flying = !_flying
            get_tree().get_root().set_input_as_handled()

        elif event.is_action_pressed(InputActions.Player.COLLISION_TOGGLE) and _dev_controls_enabled:
            _collider.disabled = not _collider.disabled
            get_tree().get_root().set_input_as_handled()

    elif event is InputEventMouseButton:
        var mw_input_scale: float = 0.1
        if event.is_action_pressed("mw_down") and _dev_controls_enabled:
            _speed_mod -= mw_input_scale
            _speed_mod = _speed_mod if _speed_mod > _min_speed else _min_speed
            get_tree().get_root().set_input_as_handled()

        elif event.is_action_pressed("mw_up") and _dev_controls_enabled:
            _speed_mod += mw_input_scale
            _speed_mod = _speed_mod if _speed_mod < _max_speed else _max_speed
            get_tree().get_root().set_input_as_handled()


func _physics_process(delta: float) -> void:
    _walk_and_jump(delta)
    move_and_slide()
    orthonormalize()


# FIXME: Sometimes the player cannot jump, this is probaly from the basis changing
## Handle player input for walking and jumping using the `InputActions.Player` input actions
func _walk_and_jump(delta: float) -> void:
    var xz_input_dir := Input.get_vector(
        InputActions.Player.LEFT,
        InputActions.Player.RIGHT,
        InputActions.Player.FORWARD,
        InputActions.Player.BACK
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
            # TODO: Test if this is framerate independent
            if y_velocity.length() >= TERMINAL_VELOCITY:
                y_velocity = global_basis.y * -TERMINAL_VELOCITY
        if Input.is_action_just_pressed(InputActions.Player.UP) and is_on_floor():
            y_velocity += _jump_velocity * global_basis.y
    else:
        var y_input_dir := Input.get_axis(InputActions.Player.DOWN, InputActions.Player.UP)
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
