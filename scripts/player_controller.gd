extends CharacterBody3D
## Handles player movement, jumping, gravity, and interaction with `Rigidbody3D` objects

const SPEED = 3
const LOOK_SENSITIVITY = 0.25
const SWAY_SENSITIVITY = 0.015
const JUMP_VELOCITY = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var mouse_input = Vector2.ZERO
var speed_mod = 1
var can_move = true

@onready var camera: Camera3D = $PlayerCamera

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _process(delta):
	# Press escape to get mouse control
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE

	# Move player
	if not is_on_floor():
		velocity.y -= gravity * delta

	if can_move:
		walk_and_jump()
		move_and_slide()

	# Rotate camera
	rotate_y(mouse_input.x * LOOK_SENSITIVITY * delta)
	camera.rotate_x(mouse_input.y * LOOK_SENSITIVITY * delta)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	mouse_input = Vector2.ZERO

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_input = Vector2(
			-event.relative.x,
			-event.relative.y
		)
	speed_mod = speed_mod + Input.get_axis(
		"mw_down", "mw_up"
	) * 0.1

	if speed_mod < 0.1: speed_mod = 0.1

## Handles player input for walking and jumping using the player_ input actions
func walk_and_jump():
	var input_direction = Input.get_vector(
		"player_left", "player_right", "player_forward", "player_back"
	)
	# var height_change = Input.get_axis(
	# 	"player_down", "player_up"
	# )

	# var direction = (global_basis * Vector3(input_direction.x, height_change, input_direction.y)).normalized()
	var direction = (global_basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED * speed_mod
		# velocity.y = direction.y * SPEED * speed_mod
		velocity.z = direction.z * SPEED * speed_mod
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * speed_mod)
		# velocity.y = move_toward(velocity.y, 0, SPEED * speed_mod)
		velocity.z = move_toward(velocity.z, 0, SPEED * speed_mod)

	if Input.is_action_just_pressed("player_up") and is_on_floor():
		velocity.y = JUMP_VELOCITY
