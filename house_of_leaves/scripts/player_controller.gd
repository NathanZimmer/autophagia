extends CharacterBody3D
## Handles player movement, jumping, gravity, and interaction with `Rigidbody3D` objects

# Copied camera code from:
# https://yosoyfreeman.github.io/article/godot/tutorial/achieving-better-mouse-input-in-godot-4-the-perfect-camera-controller/

@export_group("Mouse settings")
@export_range(1, 100, 1) var mouse_sensitivity: int = 50

@export_group("Clamp settings")
@export var max_pitch: float = 89
@export var min_pitch: float = -89

@export_group("Player movement settings")
@export var move_speed: float = 3.0
@export var jump_velocity: float = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed_mod = 1  # Modifier to player speed that can be adjusted with mouse wheel

var camera: Camera3D


func _ready():
	camera = find_children("", "Camera3D")[0]
	# Input.set_use_accumulated_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		aim_look(event)

	speed_mod = speed_mod + Input.get_axis("mw_down", "mw_up") * 0.1

	if speed_mod < 0.1:
		speed_mod = 0.1


func _process(delta: float) -> void:
	# Move player
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		walk_and_jump()
		move_and_slide()
		orthonormalize()


## Handle player input for walking and jumping using the player_ input actions
func walk_and_jump():
	var input_direction = Input.get_vector(
		"player_left", "player_right", "player_forward", "player_back"
	)

	# var direction = (global_basis * Vector3(input_direction.x, height_change, input_direction.y)).normalized()
	var direction = (global_basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed * speed_mod
		velocity.z = direction.z * move_speed * speed_mod
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * speed_mod)
		velocity.z = move_toward(velocity.z, 0, move_speed * speed_mod)

	if Input.is_action_just_pressed("player_up") and is_on_floor():
		velocity.y = jump_velocity


# Handle aim look with the mouse.
func aim_look(event: InputEventMouseMotion) -> void:
	var viewport_transform: Transform2D = get_tree().root.get_final_transform()
	var motion: Vector2 = event.xformed_by(viewport_transform).relative
	var degrees_per_unit: float = 0.001

	motion *= mouse_sensitivity
	motion *= degrees_per_unit

	add_yaw(motion.x)
	add_pitch(motion.y)
	clamp_pitch()
	camera.orthonormalize()


# Rotate the character around the local Y axis by a given amount (In degrees) to achieve yaw
func add_yaw(amount) -> void:
	if is_zero_approx(amount):
		return

	rotate_object_local(Vector3.DOWN, deg_to_rad(amount))


# Rotate the head around the local x axis by a given amount (In degrees) to achieve pitch
func add_pitch(amount) -> void:
	if is_zero_approx(amount):
		return

	camera.rotate_object_local(Vector3.LEFT, deg_to_rad(amount))


# Clamp the pitch between min_pitch and max_pitch
func clamp_pitch() -> void:
	if camera.rotation.x > deg_to_rad(min_pitch) and camera.rotation.x < deg_to_rad(max_pitch):
		return

	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
