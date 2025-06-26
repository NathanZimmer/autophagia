@tool
## Automatically create `PortalRenderer` nodes for and
## setup the link between a set of `PortalBody` nodes. [br]
## All portals are linked to the first portal in the node-tree.
## The first portal is linked to whatever portal the player passed
## through to reach it.
class_name AllToOnePortalProcessor extends PortalProcessor

var _main_portal: PortalBody


func _setup():
	var portals = find_children("*", "PortalBody", false)
	if portals.size() < 2:
		push_warning("Incorrect number of PortalBody children. This node will not process.")
		return

	_main_portal = portals[0]

	var main_renderer := (
		PortalRenderer
		. init(
			_target_cam,
			_main_portal,
			portals[1],
			_world_render_layers & ~_portal_render_layer,
		)
	)
	_main_portal.add_child(main_renderer)

	(
		_main_portal
		. reset(
			_size if _override_portal_sizes else _main_portal.size,
			[main_renderer] as Array[PortalRenderer],
			_portal_render_layer,
			0,
			_collision_layer,
			_collision_mask,
			_vis_notifier_layers,
			portals[1],
			_target_cam.get_parent(),
		)
	)
	_main_portal.player_teleported.connect(_ready_teleport_target)

	for portal in portals.slice(1):
		var renderer := (
			PortalRenderer
			. init(
				_target_cam,
				portal,
				_main_portal,
				_world_render_layers & ~_portal_render_layer,
			)
		)
		portal.add_child(renderer)

		(
			portal
			. reset(
				_size if _override_portal_sizes else portal.size,
				[renderer] as Array[PortalRenderer],
				_portal_render_layer,
				0,
				_collision_layer,
				_collision_mask,
				_vis_notifier_layers,
				_main_portal,
				_target_cam.get_parent(),
			)
		)

		portal.player_entered_portal.connect(func(): _main_portal.teleport_target = portal)
		portal.player_entered_portal.connect(main_renderer.set_reference_node.bind(portal))


## Call `prepare_for_teleport` on the current target
## of `_main_portal`
func _ready_teleport_target():
	var target = _main_portal.teleport_target
	target.prepare_for_teleport()


## Show warning if we don't have 2 portal children
func _get_configuration_warnings() -> PackedStringArray:
	var portals = find_children("*", "PortalBody", false)

	var warnings: PackedStringArray = []
	if portals.size() < 2:
		warnings.append("This node needs at least two PortalBody children to process.")

	return warnings
