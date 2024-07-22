@tool
class_name PortalContainer extends Node3D
## TODO

# TODO:
	# Add max view distance to portals
	# Add oblique projection
	# Give portals a secondary target to use in place of player camera. This allows for single-portal recursion
	# Fix issue with portal visibility check. Could be race condition. Caused by slow performance
	# Verify that the destruction and construction work properly

## Resolution scale of portals. `1.0 = full resolution`
@export_range(0.1, 1, 0.1) var resolution_scale: float = 1
## `CharacterBody3D` with a `Camera3D` child
@export var player: CharacterBody3D
## Width, height, and depth of both portals
@export var portal_size: Vector3 = Vector3(1, 2, 0.2)
## Render layer for each portal (by child order). Portal cameras cannot see their own layer
@export var render_layers: Vector2i = Vector2i(9, 10)
## Layer that portal collision will take place on
@export var trigger_layer_mask: int = 2
## Cull mask for the camera rendering the first portal's view
@export_flags_3d_render var cam_0_cull_mask
## Cull mask for the camera rendering the second portal's view
@export_flags_3d_render var cam_1_cull_mask

var portal_0: Portal
var portal_1: Portal
var viewport_0: SubViewport
var viewport_1: SubViewport
var cam_0: Camera3D
var cam_1: Camera3D
var constructed: bool = false
var deployed: bool = false
# var portals_on_screen = false

static var cam_env: Environment
static var target_cam: Camera3D
var box_mesh: BoxMesh = BoxMesh.new()

## Size of portal stash
static var queue_size: int = 3
## Queue of stashed portals. Portals are destructed when removed from the queue
static var portal_delete_queue: Array[PortalContainer] = []

## Editor-only var
var child_count = get_children().size()

func _ready():
	box_mesh.size = portal_size
	var portals = find_children('', 'Portal')

	if Engine.is_editor_hint():
		if portals.size() == 2:
			portal_0 = portals[0]
			portal_1 = portals[1]
			portal_0.update_mesh(box_mesh, render_layers.x)
			portal_1.update_mesh(box_mesh, render_layers.y)
		return

	# Environment
	var world_env = get_node('/root/Main/WorldEnvironment')
	if world_env != null and cam_env == null:
		cam_env = world_env.environment.duplicate()
		cam_env.glow_enabled = false

	# Set target cam from player
	if target_cam == null:
		target_cam = player.find_children('', 'Camera3D')[0]

	# init portal 0
	portal_0 = portals[0]
	portal_0.update_mesh(box_mesh, render_layers.x)
	var area_3d_0 = _create_collider(portal_0, trigger_layer_mask)
	add_child(area_3d_0)
	var vis_notif_0 = _create_visibility_notifier(portal_0, render_layers.x)
	# Connecting signals
	area_3d_0.connect('body_entered', func(_body): portal_0.player_in_portal = true)
	area_3d_0.connect('body_exited', func(_body): portal_0.player_in_portal = false)
	vis_notif_0.connect('screen_entered', func(): portal_0.on_screen = true)
	vis_notif_0.connect('screen_exited', func(): portal_0.on_screen = false)

	# init portal 1
	portal_1 = portals[1]
	portal_1.update_mesh(box_mesh, render_layers.y)
	var area_3d_1 = _create_collider(portal_1, trigger_layer_mask)
	add_child(area_3d_1)
	var vis_notif_1 = _create_visibility_notifier(portal_1, render_layers.y)
	# Connecting signals
	area_3d_1.connect('body_entered', func(_body): portal_1.player_in_portal = true)
	area_3d_1.connect('body_exited', func(_body): portal_1.player_in_portal = false)
	vis_notif_1.connect('screen_entered', func(): portal_1.on_screen = true)
	vis_notif_1.connect('screen_exited', func(): portal_1.on_screen = false)

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

			var portals = find_children('', 'Portal')
			if portals.size() == 2:
				portal_0 = portals[0]
				portal_1 = portals[1]
				portal_0.update_mesh(box_mesh, render_layers.x)
				portal_1.update_mesh(box_mesh, render_layers.y)
			return

		if portal_0 != null and portal_0.mesh == null:
				portal_0.update_mesh(box_mesh, render_layers.x)
		if portal_1 != null and portal_1.mesh == null:
				portal_1.update_mesh(box_mesh, render_layers.y)

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


	var oblique_cutoff = portal_size.z
	# Teleport player
	if _check_player_can_teleport(portal_0, portal_size.z / 2):
		portal_0.player_in_portal = false
		portal_1.on_screen = true
		player.global_transform = _get_transform(
			player.global_transform,
			portal_0.global_transform,
			portal_1.global_transform,
			portal_size.z / 2,
			true,
		)
		print('portal 0 entered')

	elif _check_player_can_teleport(portal_1, portal_size.z / 2):
		portal_1.player_in_portal = false
		portal_0.on_screen = true
		player.global_transform = _get_transform(
			player.global_transform,
			portal_1.global_transform,
			portal_0.global_transform,
			portal_size.z / 2,
			true,
		)
		print('portal 1 entered')

	# Only move cameras when needed
	if portal_0.on_screen:
		cam_1.global_transform = _get_transform(
			target_cam.global_transform,
			portal_0.global_transform,
			portal_1.global_transform,
			portal_size.z
		)
		# Adjust portal cam oblique position
		cam_1.use_oblique_frustum = abs(portal_0.to_local(target_cam.global_position).z) > oblique_cutoff
		# cam_1.use_oblique_frustum = cam_1.global_position.distance_to(portal_1.global_position) > oblique_cutoff
		# if cam_relative_to_portal.z > portal_size.z + camera_offset:
		# 	cam_1.oblique_position = portal_1.global_position + portal_1.basis.z * (portal_size.z / 2)
		# 	# cam_1.oblique_offset = portal_size.z / 2
		# elif cam_relative_to_portal.z < -1 * portal_size.z - camera_offset:
		# 	cam_1.oblique_position = portal_1.global_position - portal_1.basis.z * (portal_size.z / 2)
		# 	# cam_1.oblique_offset = -1 * portal_size.z / 2
		# else:
		# 	cam_1.use_oblique_frustum = false
		# 	# cam_1.oblique_position = portal_1.global_position + portal_1.basis.z * (cam_relative_to_portal.z * 0.999)
		# 	# cam_1.oblique_offset = cam_relative_to_portal.z * 0.9
	if portal_1.on_screen:
		cam_0.global_transform = _get_transform(
			target_cam.global_transform,
			portal_1.global_transform,
			portal_0.global_transform,
			portal_size.z
		)
		# Adjust portal cam oblique position
		cam_0.use_oblique_frustum = abs(portal_1.to_local(target_cam.global_position).z) > oblique_cutoff
		# cam_0.use_oblique_frustum = abs(cam_relative_to_portal_0.z) > oblique_cutoff
		# cam_0.use_oblique_frustum = cam_0.global_position.distance_to(portal_0.global_position) > oblique_cutoff
		# var cam_0_xz = Vector2(cam_0.position.x, cam_0.position.z)
		# var portal_0_xy = Vector2(portal_0.position.x , portal_0.position.z)
		# print(cam_0.global_position.distance_to(portal_0.global_position))
		# if cam_relative_to_portal.z > portal_size.z + camera_offset:
		# 	cam_0.oblique_position = portal_0.global_position + portal_0.basis.z * (portal_size.z / 2)
		# 	# cam_0.oblique_offset = portal_size.z / 2
		# elif cam_relative_to_portal.z < -1 * portal_size.z - camera_offset:
		# 	cam_0.oblique_position = portal_0.global_position - portal_0.basis.z * (portal_size.z / 2)
		# 	# cam_0.oblique_offset = -1 * portal_size.z / 2
		# else:
		# 	cam_0.use_oblique_frustum = false
		# 	# cam_0.oblique_position = portal_0.global_position + portal_0.basis.z * (cam_relative_to_portal.z * 0.999)
		# 	# cam_0.oblique_offset = cam_relative_to_portal.z * 0.9

	if cam_0 != null:
		# cam_0.use_oblique_frustum = false
		# cam_0.oblique_position = portal_0.global_position + portal_0.basis.z * (portal_size.z / 2 + 0.0001)
		# cam_0.oblique_offset = 1 * (portal_size.z / 2 + 0.0001)
		pass
	if cam_1 != null:
		# cam_1.use_oblique_frustum = false
		# cam_1.oblique_position = portal_1.global_position - portal_1.basis.z * (portal_size.z / 2 + 0.0001)
		# cam_1.oblique_offset = 1 * (portal_size.z / 2 + 0.0001)
		pass

## Get the global transform of `target` rotated into `from` basis but relative to `to` basis [br]
## Useful for copying relative positions/rotations from one node to another [br]
## `target`: Transform whose persepective is being copied [br]
## `from`: Transform that `target`'s perspective is relative to [br]
## `to`: Transform that the returned transform's perspective is relative to [br]
## `z_offset`: TODO [br]
## `z_overwrite`: TODO [br]
## Returns: `global_transform: Transform3D` global transform relative to `to`
func _get_transform(
	target: Transform3D,
	from: Transform3D,
	to: Transform3D,
	z_offset: float = 0,
	z_overwrite: bool = false,
) -> Transform3D:
	var transform_offset = from.affine_inverse() * target
	var offset_sign = -1 * sign(transform_offset.origin.z)
	if z_overwrite:
		transform_offset.origin.z = offset_sign * z_offset
	else:
		transform_offset.origin.z += offset_sign * z_offset

	return to * transform_offset

## Check if `player` is far enough into `portal` to teleport [br]
## Returns `player_can_teleport: bool`
func _check_player_can_teleport(portal: Portal, z_offset) -> bool:
	if not portal.player_in_portal:
		return false

	var player_in_portal_frame = (
		portal.basis.inverse() * (player.global_position - portal.global_position)
	)

	return abs(player_in_portal_frame.z) <= z_offset
## Create and initialize `SubViewport` and `Camera3D` objects with desired params [br]
## Returns `viewport: Subviewprt`
func _create_viewport_and_cam(
	cull_mask: int,
	portal_render_layer: int,
	cam_oblique_normal: Vector3,
	cam_oblique_pos: Vector3,
) -> SubViewport:
	var texture_size = Vector2i(DisplayServer.screen_get_size() * resolution_scale)

	# Create viewport
	var viewport = SubViewport.new()
	viewport.size = texture_size
	# NOTE: this might not be optimal
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	viewport.handle_input_locally = true

	# Create camera
	var cam = Camera3D.new()
	cam.fov = target_cam.fov
	cam.cull_mask = cull_mask
	cam.set_cull_mask_value(portal_render_layer, false)
	cam.environment = cam_env
	cam.use_oblique_frustum = true
	cam.oblique_normal = cam_oblique_normal
	cam.oblique_position = cam_oblique_pos

	# Parent camera
	viewport.add_child(cam)

	return viewport

## Create and initialize `VisibleOnScreenNotifier3D` object with desired params [br]
## `portal`: the portal that this notifier is for [br]
## `mask`: the layer that the visibility notifier will be on [br]
## Returns `vis_notif: VisibleOnScreenNotifier3D`
func _create_visibility_notifier(portal: Portal, mask: int)  -> VisibleOnScreenNotifier3D:
	# Create and set notifier
	var vis_notif = VisibleOnScreenNotifier3D.new()
	for i in range(1, 21): vis_notif.set_layer_mask_value(i, false)
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
	for i in range(1, 21): area_3d.set_collision_mask_value(i, false)
	area_3d.set_collision_mask_value(mask, true)

	# Create collider
	var collider = CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	collider.shape.size = portal.mesh.size

	# Parent node
	area_3d.add_child(collider)
	area_3d.transform = portal.transform

	return area_3d

## Initializes viewports and cameras. Sets portal material to viewport texture.
## Sets `constructed = true` and `deployed = true`
func construct() -> void:
	print('constructed')
	viewport_0 = _create_viewport_and_cam(
		cam_0_cull_mask,
		render_layers.x,
		portal_0.global_basis.z,
		portal_0.global_position,
	)
	add_child(viewport_0)
	cam_0 = viewport_0.get_child(0)

	viewport_1 = _create_viewport_and_cam(
		cam_1_cull_mask,
		render_layers.y,
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

## Enables viewports and cameras. Sets portal material to viewport texture.
## Sets `deployed = true`
func deploy() -> void:
	print('redeployed')
	# Enable viewports and cameras
	viewport_0.set_process(true)
	viewport_1.set_process(true)
	cam_0.set_process(true)
	cam_1.set_process(true)

	# Create material
	portal_1.set_material(viewport_0.get_texture())
	portal_0.set_material(viewport_1.get_texture())

	# remove from stash
	var stash_index = portal_delete_queue.bsearch(self)
	portal_delete_queue.remove_at(stash_index)
	print(portal_delete_queue)

	deployed = true

## Disables viewports and cameras. Deletes portal material. Sets `deployed = false`.
## Removes first element of `portal_delete_queue` and calls its `deconstruct()` function
func deactivate() -> void:
	print('deactivated')
	# Update queue
	if portal_delete_queue.size() >= queue_size:
		var portal_to_del = portal_delete_queue.pop_front()
		portal_to_del.deconstruct()

	portal_delete_queue.push_back(self)
	print(portal_delete_queue)

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
	print('destroyed')
	viewport_0.queue_free()
	viewport_0 = null
	cam_0 = null
	viewport_1.queue_free()
	viewport_1 = null
	cam_1 = null

	constructed = false

func _get_configuration_warnings():
	var portal_count = 0
	for child in get_children():
		if child is Portal:
			portal_count += 1

	var warnings = []
	if portal_count != 2:
		warnings.append(
			'This node does not have the correct number of Portals.
			Portal count should be 2'
		)

	return warnings
