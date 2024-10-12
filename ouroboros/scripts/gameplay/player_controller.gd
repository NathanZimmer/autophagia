extends CharacterBody3D
## Handles player movement, jumping, and gravity

signal bob_head

@export_group("Camera settings")
@export_range(1, 100, 1) var mouse_sensitivity: int = 50
@export var max_x_rotation: float = 89
@export var min_x_rotation: float = -89
## The angle that the camera will rotate along the z axis when head-bobbing
@export var bob_angle: int = 45
## The time it will take for the camera to rotate from 0 degrees to `bob_angle` degrees
@export var bob_time: float = 0.01

@export_group("Player movement settings")
@export var move_speed: float = 3.0
@export var jump_velocity: float = 4.5

@export_group("Dev controls")
@export var dev_controls_enabled = true
@export var min_speed: float = 0.1
@export var max_speed: float = 10

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed_mod = 1  # Modifier to player speed that can be adjusted with mouse wheel
var flying: bool = false
var collider: CollisionShape3D
var paused: bool = false

var camera: Camera3D


func _ready():
	camera = find_children("", "Camera3D")[0]
	collider = find_children("", "CollisionShape3D")[0]
	# Input.set_use_accumulated_input(false)

	Globals.pause.connect(pause)
	Globals.unpause.connect(unpause)

	await _bob_head()


func _input(event) -> void:
	if paused:
		return

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


func _process(delta: float) -> void:
	if paused:
		return

	# Move player
	if not is_on_floor() and not flying:
		velocity.y -= gravity * delta

	if Input.mouse_mode:
		_walk_and_jump()
		move_and_slide()
		orthonormalize()

## Bobs player back and forth while the player is walking
func _bob_head():
	var angle: float = deg_to_rad(bob_angle)
	var state: int = 0 # temp var, 0 = center to left, 1 = left to center, 2 = center to right, 3 = right to center
	var rotation_test: int = 0
	while true:
		match state:
			0:
				rotation_test = lerp(rotation_test, bob_angle, bob_time)
				if rotation_test == bob_angle:
					state = 1
			1:
				rotation_test = lerp(rotation_test, 0, bob_time)
				if rotation_test == 0:
					state = 2
			2:
				rotation_test = lerp(rotation_test, -1 * bob_angle, bob_time)
				if rotation_test == -1 * bob_angle:
					state = 3
			3:
				rotation_test = lerp(rotation_test, 0, bob_time)
				if rotation_test == 0:
					state = 0

		print(rotation_test)
		await bob_head


## Handle player input for walking and jumping using the player_ input actions
func _walk_and_jump():
	# if (
	# 	Input.is_action_just_released("player_left")
	# 	or Input.is_action_just_released("player_right")
	# 	or Input.is_action_just_released("player_forward")
	# 	or Input.is_action_just_released("player_back")
	# ):
	# 	stop_headbob.emit()

	var input_direction = Input.get_vector(
		"player_left", "player_right", "player_forward", "player_back"
	)
	var height_change = Input.get_axis("player_down", "player_up")

	var direction
	if flying:
		direction = (
			(global_basis * Vector3(input_direction.x, height_change, input_direction.y))
			. normalized()
		)
	else:
		direction = (global_basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	if direction:
		bob_head.emit()
		velocity.x = direction.x * move_speed * speed_mod
		if flying:
			velocity.y = direction.y * move_speed * speed_mod
		velocity.z = direction.z * move_speed * speed_mod
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * speed_mod)
		if flying:
			velocity.y = move_toward(velocity.y, 0, move_speed * speed_mod)
		velocity.z = move_toward(velocity.z, 0, move_speed * speed_mod)

	if Input.is_action_just_pressed("player_up") and is_on_floor() and not flying:
		velocity.y = jump_velocity


## Handle mouse input for camera rotation
func _rotate_cam(event: InputEventMouseMotion) -> void:
	var viewport_transform: Transform2D = get_tree().root.get_final_transform()
	var motion: Vector2 = event.xformed_by(viewport_transform).relative
	var degrees_per_unit: float = 0.001

	motion *= mouse_sensitivity
	motion *= degrees_per_unit

	rotate_object_local(Vector3.DOWN, deg_to_rad(motion.x))
	camera.rotate_object_local(Vector3.LEFT, deg_to_rad(motion.y))
	camera.rotation.x = clamp(
		camera.rotation.x, deg_to_rad(min_x_rotation), deg_to_rad(max_x_rotation)
	)
	camera.orthonormalize()


## Handle global pause signal
func pause():
	paused = true

## Handle global unpause signal
func unpause():
	paused = false