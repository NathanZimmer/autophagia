@tool
class_name PortalContainer extends Node3D
## Handles connection, displaying, and teleportation between two `Portal` objects

const PLAYER_NAME = "Player"
const WORLD_ENV_NAME = "WorldEnvironment"
const QUEUE_SIZE = 1
const ENV_OVERWRITES = {
	# 'ssao_enabled': false,
	# "sdfgi_enabled": false,
	"glow_enabled": false,
	"tonemap_mode": Environment.TONE_MAPPER_LINEAR,
	"tonemap_exposure": 1.0,
}
const CAM_ATTRIB_OVERWRITES = {
# 'auto_exposure_enabled': false,
}
const PORTAL_CAM_FAR_PLANE = 50

## Width, height, and depth of both portals
@export var portal_size: Vector3 = Vector3(1, 2, 0.2)
@export var portals_enabled: bool = true

@export_group("Rendering")
## Resolution scale of portals. `1.0 = full resolution`
@export_range(0.1, 1, 0.1) var resolution_scale: float = 1.0
## Render layer for both portals. This layer will be disabled for each portal's camera
@export var render_layer: int = 10
## Cull mask for the camera rendering the first portal's view
@export_flags_3d_render var cam_0_cull_mask = 3
## Cull mask for the camera rendering the second portal's view
@export_flags_3d_render var cam_1_cull_mask = 3

@export_group("Collision")
## Layer that portal collision will take place on
@export var trigger_layer_mask: int = 2

var portal_0: Portal
var portal_1: Portal
var viewport_0: SubViewport
var viewport_1: SubViewport
var cam_0: Camera3D
var cam_1: Camera3D
var constructed: bool = false
var deployed: bool = false
var scene_root: Node3D
var box_mesh: BoxMesh = BoxMesh.new()  # Needed for viewing the portal meshes in the editor
## Editor-only var
var child_count = get_children().size()

static var player: CharacterBody3D
static var cam_env: WorldEnvironment
static var target_cam: Camera3D
## Queue of stashed portals. Portals are destroyed when removed from the queue
static var portal_delete_queue: Array[WeakRef] = []


func _ready():
	box_mesh.size = portal_size
	var portals = find_children("", "Portal")

	if Engine.is_editor_hint():
		if portals.size() == 2:
			portal_0 = portals[0]
			portal_1 = portals[1]
			portal_0.update_mesh(box_mesh, render_layer)
			portal_1.update_mesh(box_mesh, render_layer)
		return

	# Connect signals
	Globals.change_resolution_scale.connect(_update_viewport_resolution_scale)
	Globals.toggle_fullscreen.connect(_resize_viewports)
	Globals.change_fov.connect(_change_fov)
	get_tree().get_root().size_changed.connect(_resize_viewports)

	# Portal container expects the root scene to have a world env instance
	scene_root = get_tree().get_root().get_child(1)

	# Create camera environment, disable troublesome effects
	var world_env: WorldEnvironment = scene_root.get_node(WORLD_ENV_NAME)
	if world_env != null and cam_env == null:
		cam_env = WorldEnvironment.new()

		if world_env.environment != null:
			cam_env.environment = world_env.environment.duplicate()
		if world_env.camera_attributes != null:
			cam_env.camera_attributes = world_env.camera_attributes.duplicate()

		# Set environment overrides
		for param in ENV_OVERWRITES:
			var value = ENV_OVERWRITES[param]
			cam_env.environment.set(param, value)

		# Set cam attribute overrides
		for param in CAM_ATTRIB_OVERWRITES:
			var value = CAM_ATTRIB_OVERWRITES[param]
			cam_env.camera_attributes.set(param, value)

	# Set target cam from player
	if player == null:
		player = scene_root.get_node(PLAYER_NAME)
		target_cam = player.find_children("", "Camera3D")[0]

	# Init portal 0
	portal_0 = portals[0]
	portal_0.update_mesh(box_mesh, render_layer)
	var area_3d_0 = _create_collider(portal_0, trigger_layer_mask)
	add_child(area_3d_0)
	var vis_notif_0 = _create_visibility_notifier(portal_0, render_layer)
	# Connect signals
	area_3d_0.connect("body_entered", func(_body): portal_0.player_in_portal = true)
	area_3d_0.connect("body_exited", func(_body): portal_0.player_in_portal = false)
	vis_notif_0.connect("screen_entered", func(): portal_0.on_screen = true)
	vis_notif_0.connect("screen_exited", func(): portal_0.on_screen = false)

	# Init portal 1
	portal_1 = portals[1]
	portal_1.update_mesh(box_mesh, render_layer)
	var area_3d_1 = _create_collider(portal_1, trigger_layer_mask)
	add_child(area_3d_1)
	var vis_notif_1 = _create_visibility_notifier(portal_1, render_layer)
	# Connect signals
	area_3d_1.connect("body_entered", func(_body): portal_1.player_in_portal = true)
	area_3d_1.connect("body_exited", func(_body): portal_1.player_in_portal = false)
	vis_notif_1.connect("screen_entered", func(): portal_1.on_screen = true)
	vis_notif_1.connect("screen_exited", func(): portal_1.on_screen = false)

	if not portals_enabled:
		portal_0.hide()
		portal_1.hide()


func _process(_delta):
	if Engine.is_editor_hint():
		update_configuration_warnings()
		box_mesh.size = portal_size

		# Verify that portals are still children when children change
		var cur_child_count = get_children().size()
		if child_count != cur_child_count:
			child_count = cur_child_count
			portal_0 = null
			portal_1 = null

			var portals = find_children("", "Portal")
			if portals.size() == 2:
				portal_0 = portals[0]
				portal_1 = portals[1]
				portal_0.update_mesh(box_mesh, render_layer)
				portal_1.update_mesh(box_mesh, render_layer)
			return

		# Ensure portal meshes are assigned in the editor
		if portal_0 != null and portal_0.mesh == null:
			portal_0.update_mesh(box_mesh, render_layer)
		if portal_1 != null and portal_1.mesh == null:
			portal_1.update_mesh(box_mesh, render_layer)

		# Reflecting visibility in the editor
		if not portals_enabled:
			portal_0.hide()
			portal_1.hide()

		return

	if not portals_enabled:
		return

	var portals_on_screen = portal_0.on_screen or portal_1.on_screen
	var player_in_portals = portal_0.player_in_portal or portal_1.player_in_portal

	# Construct/deploy if the player can see either portal or if the player is in either portal
	if (portals_on_screen or player_in_portals) and not deployed:
		if not constructed:
			construct()
		elif not deployed:
			deploy()
	# Deactivate if neither portal is on the screen and the player is not in either portal
	elif not (portals_on_screen or player_in_portals) and deployed:
		deactivate()
		return

	# Teleport player
	if _check_player_can_teleport(portal_0, portal_size.z / 2):
		portal_0.player_in_portal = false
		portal_1.on_screen = true
		player.global_transform = _get_relative_transform(
			player.global_transform,
			portal_0.global_transform,
			portal_1.global_transform,
			portal_size.z,
		)
	elif _check_player_can_teleport(portal_1, portal_size.z / 2):
		portal_1.player_in_portal = false
		portal_0.on_screen = true
		player.global_transform = _get_relative_transform(
			player.global_transform,
			portal_1.global_transform,
			portal_0.global_transform,
			portal_size.z,
		)

	# Only move cameras when needed
	if portal_0.on_screen:
		cam_1.global_transform = _get_relative_transform(
			target_cam.global_transform,
			portal_0.global_transform,
			portal_1.global_transform,
			portal_size.z,
		)
		cam_1.orthonormalize()
		# Disable oblique frustum when the player is inside portal to prevent flickering issue
		cam_1.use_oblique_frustum = (abs(portal_0.to_local(target_cam.global_position).z) > portal_size.z)

	if portal_1.on_screen:
		cam_0.global_transform = _get_relative_transform(
			target_cam.global_transform,
			portal_1.global_transform,
			portal_0.global_transform,
			portal_size.z,
		)
		cam_0.orthonormalize()
		# Disable oblique frustum when the player is inside portal to prevent flickering issue
		cam_0.use_oblique_frustum = (abs(portal_1.to_local(target_cam.global_position).z) > portal_size.z)


## Calculate the transform (position and rotation) offset from `current` to `reference` and return the
## transform of that same offset relative to `target`. Optionally, apply a z offest/overwrite to the output [br]
## `current`: The transform of interest [br]
## `reference`: The transform to get the offset from [br]
## `target`: The transform to apply the offest to [br]
## `z_offset`: Optional, z offset to apply before transform is rotated from `reference` into `target` perspective [br]
## Returns `relative_transform`: The transform with the equivilant offset to `target` as `current` is to `reference`
func _get_relative_transform(
	current: Transform3D,
	reference: Transform3D,
	target: Transform3D,
	z_offset: float = 0,
) -> Transform3D:
	var transform_offset = reference.affine_inverse() * current  # Get current relative to reference
	var offset_sign = -1 * sign(transform_offset.origin.z)
	transform_offset.origin.z += offset_sign * z_offset

	return target * transform_offset  # Return new transform relativate to target


## Check if `player`'s z offset from `portal` is less than `z_offset` [br]
## Returns `player_can_teleport: bool`
func _check_player_can_teleport(portal: Portal, z_offset) -> bool:
	if not portal.player_in_portal:
		return false

	var player_in_portal_frame = portal.to_local(player.global_position)

	return abs(player_in_portal_frame.z) <= z_offset


## Create and initialize `SubViewport` and `Camera3D` objects with desired params [br]
## Returns `viewport: Subviewprt` [br]
## `cull_mask`: The created camera's cull mask [br]
## `portal_render_layer`: The render layer the portal will display on,
## this layer is disabled for the created camera [br]
## `cam_oblique_normal`: The normal direction of the portal this camera is for [br]
## `cam_oblique_pos`: The position of the portal this camera is for [br]
## `cam_far_plane`: Optional, the far plane of the created camera [br]
## Returns `viewport`: a `Subviewport` with a `Camera3D` child
func _create_viewport_and_cam(
	cull_mask: int,
	portal_render_layer: int,
	cam_oblique_normal: Vector3,
	cam_oblique_pos: Vector3,
	cam_far_plane: float = PORTAL_CAM_FAR_PLANE,
) -> SubViewport:
	var texture_size = Vector2i(DisplayServer.screen_get_size() * resolution_scale)

	# Create viewport
	var viewport = SubViewport.new()
	viewport.size = texture_size
	# NOTE: this might not be optimal
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	viewport.handle_input_locally = true
	viewport.msaa_3d = ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")

	# Create camera
	var cam = Camera3D.new()
	cam.fov = target_cam.fov
	cam.cull_mask = cull_mask
	cam.set_cull_mask_value(portal_render_layer, false)
	cam.environment = cam_env.environment
	cam.attributes = cam_env.camera_attributes
	cam.use_oblique_frustum = true
	cam.oblique_normal = cam_oblique_normal
	cam.oblique_position = cam_oblique_pos
	cam.far = cam_far_plane

	# Parent camera
	viewport.add_child(cam)

	return viewport


## Create and initialize `VisibleOnScreenNotifier3D` object with desired params [br]
## `portal`: the portal that this notifier is for [br]
## `mask`: the layer that the visibility notifier will be on [br]
## Returns `vis_notif: VisibleOnScreenNotifier3D`
func _create_visibility_notifier(portal: Portal, mask: int) -> VisibleOnScreenNotifier3D:
	# Create and set notifier
	var vis_notif = VisibleOnScreenNotifier3D.new()
	for i in range(1, 21):
		vis_notif.set_layer_mask_value(i, false)
	vis_notif.set_layer_mask_value(mask, true)
	add_child(vis_notif)
	vis_notif.transform = portal.transform
	vis_notif.aabb = AABB(
		portal.mesh.size / -2,
		portal.mesh.size,
	)

	return vis_notif


## Create and initialize `Area3D` and an associated box collider [br]
## `portal`: the portal to create `Area3D` for [br]
## `mask`: the layer the `Area3D` checks for collisions on [br]
## Returns `area_3d: Area3D`
func _create_collider(portal: Portal, mask: int) -> Area3D:
	# Create area
	var area_3d = Area3D.new()
	for i in range(1, 21):
		area_3d.set_collision_mask_value(i, false)
	area_3d.set_collision_mask_value(mask, true)

	# Create collider
	var collider = CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	collider.shape.size = portal.mesh.size

	# Parent node
	area_3d.add_child(collider)
	area_3d.transform = portal.transform

	return area_3d


## Initializes viewports and cameras, sets viewport and camera variables,
## sets portal materials to viewport textures, sets `constructed = true` and `deployed = true`
func construct() -> void:
	viewport_0 = _create_viewport_and_cam(
		cam_0_cull_mask,
		render_layer,
		portal_0.global_basis.z,
		portal_0.global_position,
	)
	add_child(viewport_0)
	cam_0 = viewport_0.get_child(0)

	viewport_1 = _create_viewport_and_cam(
		cam_1_cull_mask,
		render_layer,
		portal_1.global_basis.z,
		portal_1.global_position,
	)
	add_child(viewport_1)
	cam_1 = viewport_1.get_child(0)

	# Set portal materials
	portal_1.set_material(viewport_0.get_texture())
	portal_0.set_material(viewport_1.get_texture())

	constructed = true
	deployed = true


## Enables viewports and cameras, sets portal material to viewport textures,
## sets `deployed = true`
func deploy() -> void:
	# Enable viewports and cameras
	viewport_0.set_process(true)
	viewport_1.set_process(true)
	cam_0.set_process(true)
	cam_1.set_process(true)

	# Create material
	portal_1.set_material(viewport_0.get_texture())
	portal_0.set_material(viewport_1.get_texture())

	# remove from stash
	var stash_index = portal_delete_queue.bsearch(weakref(self))
	portal_delete_queue.remove_at(stash_index)

	deployed = true


## Disables viewports and cameras, deletes portal materials, sets `deployed = false`,
## removes first element of `portal_delete_queue` and calls its `deconstruct()` function
func deactivate() -> void:
	# Update queue
	if portal_delete_queue.size() >= QUEUE_SIZE:
		var portal_to_del = portal_delete_queue.pop_front()
		if portal_to_del.get_ref():
			portal_to_del.get_ref().deconstruct()

	portal_delete_queue.push_back(weakref(self))

	# Deactivate
	portal_0.remove_material()
	portal_1.remove_material()
	if viewport_0 != null:
		viewport_0.set_process(false)
	if viewport_1 != null:
		viewport_1.set_process(false)
	if cam_0 != null:
		cam_0.set_process(false)
	if cam_1 != null:
		cam_1.set_process(false)

	deployed = false


## Frees `viewport_0` and `viewport_1` (and their nested cameras). sets `constructed = false`
func deconstruct() -> void:
	viewport_0.queue_free()
	viewport_0 = null
	cam_0 = null
	viewport_1.queue_free()
	viewport_1 = null
	cam_1 = null

	constructed = false


func show_portals() -> void:
	portals_enabled = true
	if portal_0 != null:
		portal_0.show()
	if portal_1 != null:
		portal_1.show()


func hide_portals() -> void:
	portals_enabled = false
	if portal_0 != null:
		portal_0.hide()
	if portal_1 != null:
		portal_1.hide()


func _update_viewport_resolution_scale(scale: int) -> void:
	if viewport_0 == null or viewport_1 == null:
		return

	viewport_0.scaling_3d_scale = scale
	viewport_1.scaling_3d_scale = scale


func _resize_viewports() -> void:
	if viewport_0 == null or viewport_1 == null:
		return

	var size = get_viewport().size
	# var expected_ratio = 16.0 / 9.0
	# var ratio = (size.x * 1.0) / size.y

	# if ratio > expected_ratio:
	# 	var new_x = int(size.y * expected_ratio)
	# 	size.x = new_x
	# elif ratio < expected_ratio:
	# 	var new_y = int(size.x / expected_ratio)
	# 	size.y = new_y

	viewport_0.size = size
	viewport_1.size = size


func _change_fov(fov: int) -> void:
	if cam_0 == null or cam_1 == null:
		return

	cam_0.fov = fov
	cam_1.fov = fov


func _get_configuration_warnings():
	var portal_count = 0
	for child in get_children():
		if child is Portal:
			portal_count += 1

	var warnings = []
	if portal_count != 2:
		warnings.append("This node does not have the correct number of Portals. \nPortal count should be 2")

	return warnings
