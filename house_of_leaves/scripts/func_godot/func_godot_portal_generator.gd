@tool
extends Node
## Uses `_func_godot_build_complete` to create or find a `PortalContainer` with the `portal_id` from this portal's properties.
## Gives it a `Portal` child with this object's mesh and position [br]
## This is kinda jenky and breaks if the child mesh isn't a rectangle, but I don't want to rewrite my portal code and the show must go on so... ¯\_(ツ)_/¯

@export var func_godot_properties: Dictionary

func _ready():
	if Engine.is_editor_hint():
		return

	# Accounting for the two possible group hierarchies
	var map_root: FuncGodotMap
	if get_parent() is FuncGodotMap:
		map_root = get_parent()
	else:
		map_root = get_parent().get_parent()

	# Creating or getting container
	var container_name = 'PortalContainer' + str(func_godot_properties['portal_id'])
	var container = map_root.find_child(container_name)

	# Connecting show signals
	if func_godot_properties['attach_signal']:
		var signal_hide = 'hide_' + str(func_godot_properties['signal_id'])
		if not Globals.has_user_signal(signal_hide):
			Globals.add_user_signal(signal_hide)
		if not Globals.is_connected(signal_hide, container.hide_portals):
			Globals.connect(signal_hide, container.hide_portals)

		var signal_show = 'show_' + str(func_godot_properties['signal_id'])
		if not Globals.has_user_signal(signal_show):
			Globals.add_user_signal(signal_show)
		if not Globals.is_connected(signal_show, container.show_portals):
			Globals.connect(signal_show, container.show_portals)

func _func_godot_build_complete():
	# Accounting for the two possible group hierarchies
	var map_root: FuncGodotMap
	if get_parent() is FuncGodotMap:
		map_root = get_parent()
	else:
		map_root = get_parent().get_parent()

	# Creating or getting container
	var container_name = 'PortalContainer' + str(func_godot_properties['portal_id'])
	var container = map_root.find_child(container_name)

	if container == null:
		container = PortalContainer.new()
		map_root.add_child(container)
		container.owner = map_root.owner
		container.name = container_name

	# Setting portal size
	var mesh_instance = get_child(0)
	var mesh_size = _get_mesh_size(mesh_instance.mesh)
	container.portal_size = mesh_size

	# Giving the container a portal with this position and rotation
	var portal = Portal.new()
	container.add_child(portal)
	portal.owner = map_root.owner
	portal.global_position = mesh_instance.global_position
	portal.global_rotation = func_godot_properties['rotation'] * PI / 180

	# Hiding placeholder mesh
	mesh_instance.hide()

	# Applying default visiblity
	if not func_godot_properties['visible']:
		container.hide_portals()

## Get the size of the given mesh using `MeshDataTool`
func _get_mesh_size(mesh: Mesh):
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	return abs(mdt.get_vertex(0)) * 2
