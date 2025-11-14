extends CharacterBody3D
## Handles player movement, jumping, and gravity

const TERMINAL_VELOCITY := 50.0
## If true, this script will control mouse capture mode with "ui_cancel" input.
## Use for scenes where the gui scripts aren't loaded and input isn't captured.
const DEBUG_CAPTURE_MOUSE := false

@export_group("Camera settings")
# @export_range(1, 100, 1) var _mouse_sensitivity := 50
@export var _min_x_rotation := -89.0
@export var _max_x_rotation := 89.0

@export_group("Player movement settings")
@export var _move_speed := 3.0
## The upward velocity of a jump
@export var _jump_velocity := 4.5
@export_subgroup("Velocity Deltas")
@export var _start_delta := 0.05
@export var _stop_delta := 0.03
@export var _air_delta := 0.02

@export_group("Dev controls")
@export var _dev_controls_enabled := true
@export var _override_up_dir_on_ready := true
@export var _min_speed := 0.1
@export var _max_speed := 10.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _speed_mod := 1.0  # Modifier to player speed that can be adjusted with mouse wheel
var _flying := false
var _mouse_sensitivity := 50
var _mouse_inverted := false

@onready var camera := %Camera3D
@onready var _collider := %CollisionShape3D
# @onready var _camera_animation_player: AnimationPlayer = %CameraAnimationPlayer
@onready var _camera_animation_tree: AnimationTree = %CameraAnimationTree


func _ready() -> void:
    # Input.set_use_accumulated_input(false)

    if _override_up_dir_on_ready:
        up_direction = global_basis.y

    _link_runtime_configurables()

    if DEBUG_CAPTURE_MOUSE:
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

        elif (
            event.is_action_pressed(InputActions.Player.COLLISION_TOGGLE) and _dev_controls_enabled
        ):
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
    if _camera_animation_tree:
        _camera_animation_tree.update_state(velocity, is_on_floor(), _move_speed * _speed_mod)


func _link_runtime_configurables() -> void:
    _set_mouse_sensitivity(Overrides.load_mouse_sensitivity())
    Overrides.mouse_sensitivity_changed.connect(_set_mouse_sensitivity)
    _set_mouse_inverted(Overrides.load_mouse_inverted())
    Overrides.mouse_inverted_changed.connect(_set_mouse_inverted)
    _set_fov(Overrides.load_fov())
    Overrides.field_of_view_changed.connect(_set_fov)


## Handle player input for walking and jumping using the `InputActions.Player` input actions
func _walk_and_jump(delta: float) -> void:
    var xz_velocity := (
        Input.get_vector(
            InputActions.Player.LEFT,
            InputActions.Player.RIGHT,
            InputActions.Player.FORWARD,
            InputActions.Player.BACK
        )
        * _move_speed
        * _speed_mod
    )
    var local_velocity := global_basis.inverse() * velocity

    var velocity_delta := (
        (
            _start_delta
            if (
                Vector2(local_velocity.x, local_velocity.z).length_squared()
                < xz_velocity.length_squared()
            )
            else _stop_delta
        )
        if is_on_floor() or _flying
        else _air_delta
    )
    velocity_delta *= _speed_mod
    local_velocity.x = move_toward(local_velocity.x, xz_velocity.x, velocity_delta)
    local_velocity.z = move_toward(local_velocity.z, xz_velocity.y, velocity_delta)

    if not _flying:
        if Input.is_action_just_pressed(InputActions.Player.UP) and is_on_floor():
            local_velocity.y += _jump_velocity
        else:
            local_velocity.y -= _gravity * delta
            if local_velocity.y >= TERMINAL_VELOCITY:
                local_velocity.y = -TERMINAL_VELOCITY
    else:
        var y_input_dir := Input.get_axis(InputActions.Player.DOWN, InputActions.Player.UP)
        local_velocity.y = move_toward(
            local_velocity.y, y_input_dir * _move_speed * _speed_mod, velocity_delta
        )

    velocity = global_basis * local_velocity


## Handle mouse input for camera rotation [br]
## ## Parameters [br]
## `event`: mouse movement to be used to rotate the camera.
func _rotate_cam(event: InputEventMouseMotion) -> void:
    var viewport_transform: Transform2D = get_tree().root.get_final_transform()
    var motion: Vector2 = event.xformed_by(viewport_transform).relative
    var degrees_per_unit: float = 0.001

    motion *= _mouse_sensitivity * degrees_per_unit

    rotate_object_local(Vector3.DOWN, deg_to_rad(motion.x))
    camera.rotate_object_local(
        Vector3.LEFT, deg_to_rad(-1 * motion.y if _mouse_inverted else motion.y)
    )
    camera.rotation.x = clamp(
        camera.rotation.x, deg_to_rad(_min_x_rotation), deg_to_rad(_max_x_rotation)
    )
    camera.orthonormalize()


func _set_mouse_sensitivity(value: int) -> void:
    _mouse_sensitivity = value


func _set_mouse_inverted(value: bool) -> void:
    _mouse_inverted = value


func _set_fov(value: int) -> void:
    camera.fov = value
