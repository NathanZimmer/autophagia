@tool
## TODO
class_name PortalBody extends Node3D

const MATERIAL_PATH = "uid://b3gfilq0wguq8"
const VIEWPORT_SHADER_PARAM = "viewport_textures"
const RECURSION_PASS_THROUGH_COLOR = Color.MAGENTA
# const EDITOR_DISPLAY_COLOR_0 = Color.BLUE
# const EDITOR_DISPLAY_COLOR_1 = Color.ORANGE
# const EDITOR_DISPLAY_ALPHA = 0.25

# @export_tool_button("Enable/Disable editor debug", "Callable") var debug = _run_editor_debug

@export_group("Portal Dimensions")
## Size of this portal
@export var _size := Vector3.ONE :
    set(value):
        if value == _size:
            return
        _size = value

        if Engine.is_editor_hint():
            # _upate_editor_mesh()
            pass

    get():
        return _size

@export_group("Reference Targets")
## Teleport the player to this node on traveling through this portal
@export var _teleport_target: Node3D
## The player
@export var _player: PhysicsBody3D
@export_group("Rendering")
## Layers to render on
@export_flags_3d_render var _render_layers := 2 :
    set(value):
        if value == _render_layers:
            return
        _render_layers = value

        if not Engine.is_editor_hint() and _mesh != null:
            _mesh.layers = _render_layers

    get():
        return _render_layers

## Layers for the `VisibleOnScreenNotifier3D` to check on
@export_flags_3d_render var _vis_notifier_render_layers := 0 :
    set(value):
        if value == _vis_notifier_render_layers:
            return
        _vis_notifier_render_layers = value

        if not Engine.is_editor_hint() and _vis_notifier != null:
            _vis_notifier.layers = _vis_notifier_render_layers

    get():
        return _vis_notifier_render_layers

## Layers to render the secondary mesh to. This can be used to indicate when
## this portal is seen through another portal it shouldn't be or for portal recursion
@export_flags_3d_render var _recursion_render_layers := 0 :
    set(value):
        if value == _recursion_render_layers:
            return
        _recursion_render_layers = value

        if not Engine.is_editor_hint() and _recursion_mesh != null:
            _recursion_mesh.layers = _render_layers

    get():
        return _recursion_render_layers

@export_group("Collision")
## Collision layers for this portal's Area3D
@export_flags_3d_physics var _collision_layer := 1 :
    set(value):
        if value == _collision_layer:
            return
        _collision_layer = value

        if not Engine.is_editor_hint() and _area_3d != null:
            _area_3d._collision_layer = _collision_layer

    get():
        return _collision_layer

## Collision mask for this portal's Area3D
@export_flags_3d_physics var _collision_mask := 1 :
    set(value):
        if value == _collision_mask:
            return
        _collision_mask = value

        if not Engine.is_editor_hint() and _area_3d != null:
            _area_3d._collision_mask = _collision_mask

    get():
        return _collision_mask

var _renderers: Array[PortalRenderer]

var _material: ShaderMaterial = preload(MATERIAL_PATH).duplicate()
var _mesh: MeshInstance3D
## Mesh for viewing this portal through another portal. Useful
## for debugging or portal recursion
var _recursion_mesh: MeshInstance3D
var _area_3d: Area3D
var _vis_notifier: VisibleOnScreenNotifier3D

var _player_in_portal := false
var _portal_on_screen := false

## Whether the player was on the front or back side of this node's
## z-plane for the last frame
var _player_direction_sign: float
var _player_teleported_last_frame := false

# var _editor_debug = false
# var _editor_mesh_0: MeshInstance3D = null
# var _editor_mesh_1: MeshInstance3D = null

signal portal_entered_screen
signal portal_exited_screen
signal player_teleported
signal player_entered_portal
signal player_exited_portal


func _ready() -> void:
    if Engine.is_editor_hint():
        # _upate_editor_mesh()
        return

    # if teleport_target is PortalBody:
    #     PortalProcessor.setup_signals(
    #         portal_renderers[0],
    #         teleport_target.portal_renderers[0],
    #         self,
    #         teleport_target,
    #     )

    _renderers.assign(find_children("*", "PortalRenderer", false))

    _setup()


func _physics_process(_0) -> void:
    if Engine.is_editor_hint():
        return

    var current_frame_angle = global_basis.z.dot(global_position - _player.global_position)
    var current_direction_sign = signf(current_frame_angle)

    # FIXME: If the player moves into and out of a portal on back-to-back frames they
    # will be teleported twice the distance they should be.
    if (
        _player_in_portal
        and current_direction_sign != _player_direction_sign
        and not _player_teleported_last_frame
        ):
        _teleport_player()
        _player_teleported_last_frame = true
    else:
        update_portal_pos()
        _player_teleported_last_frame = false

    _player_direction_sign = current_direction_sign


## Reinitialize with a new set of parameters [br]
## NOTE: all nodes in `renderers` are saved as children of
## this node [br]
## TODO: Param descriptions
func reset(
    size: Vector3,
    renderers: Array[PortalRenderer],
    render_layers: int,
    recursion_render_layers: int,
    collision_layer: int,
    collision_mask: int,
    vis_notifier_render_layers: int,
    teleport_target: Node3D,
    player: PhysicsBody3D,
) -> void:
    _size = size
    _renderers = renderers
    for renderer in _renderers:
        add_child(renderer)
    _render_layers = render_layers
    _recursion_render_layers = recursion_render_layers
    _collision_layer = collision_layer
    _collision_mask = collision_mask
    _vis_notifier_render_layers = vis_notifier_render_layers
    _teleport_target = teleport_target
    _player = player

    _setup()


func _setup() -> void:
    if is_instance_valid(_mesh):
        _mesh.queue_free()
    if is_instance_valid(_area_3d):
        _area_3d.queue_free()
    if is_instance_valid(_vis_notifier):
        _vis_notifier.queue_free()

    if _renderers.size() > 0:
        _renderers[0]._target_reference_node = self
        player_entered_portal.connect(func(): _renderers[0].use_oblique_frustum = false)
        player_exited_portal.connect(func(): _renderers[0].use_oblique_frustum = true)

    _mesh = _create_mesh(_material)
    _area_3d = _create_area_3d()
    _vis_notifier = _create_visiblity_notifier()

    var recursion_pass_material = StandardMaterial3D.new()
    recursion_pass_material.albedo_color = RECURSION_PASS_THROUGH_COLOR
    recursion_pass_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _recursion_mesh = _create_mesh(recursion_pass_material)
    _recursion_mesh.layers = _recursion_render_layers

    _reset_viewport_shader_param()
    var current_frame_angle = global_basis.z.dot(global_position - _player.global_position)
    _player_direction_sign = signf(current_frame_angle)

    if _teleport_target is PortalBody:
        player_teleported.connect(_teleport_target.prepare_for_teleport)


## Create and configure the mesh for this portal. [br]
## NOTE: This mesh is only half the depth of the mesh in the
## Editor.
func _create_mesh(mesh_material: Material) -> MeshInstance3D:
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(_size.x, _size.y, _size.z / 2)
    box_mesh.material = mesh_material

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = box_mesh
    mesh_instance.layers = _render_layers
    mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

    if not Engine.is_editor_hint():
        add_child(mesh_instance)
    mesh_instance.global_transform = global_transform

    # if _editor_debug:
    #     mesh_instance.owner = get_tree().edited_scene_root
    return mesh_instance


## Create and configure the on-screen visibility notifier
## for this portal
func _create_visiblity_notifier() -> VisibleOnScreenNotifier3D:
    var vis_notifier = VisibleOnScreenNotifier3D.new()
    vis_notifier.layers = _vis_notifier_render_layers
    add_child(vis_notifier)
    vis_notifier.aabb = AABB(_size / -2, _size)

    vis_notifier.screen_entered.connect(
        func():
            _portal_on_screen = true
            portal_entered_screen.emit()
    )
    vis_notifier.screen_exited.connect(
        func():
            _portal_on_screen = false
            portal_exited_screen.emit()
    )

    # if _editor_debug:
    #     vis_notifier.owner = get_tree().edited_scene_root
    return vis_notifier


## Create and configure the Area3D for this portal
func _create_area_3d() -> Area3D:
    var area_3d = Area3D.new()
    area_3d._collision_layer = _collision_layer
    area_3d._collision_mask = _collision_mask

    var collider = CollisionShape3D.new()
    collider.shape = BoxShape3D.new()
    collider.shape.size = _size

    area_3d.add_child(collider)
    add_child(area_3d)
    area_3d.global_transform = global_transform

    area_3d.body_entered.connect(
        func(_body):
            _player_in_portal = true
            player_entered_portal.emit()
    )
    area_3d.body_exited.connect(
        func(_body):
            _player_in_portal = false
            player_exited_portal.emit()
    )

    # if _editor_debug:
    #     area_3d.owner = get_tree().edited_scene_root
    #     collider.owner = get_tree().edited_scene_root
    return area_3d


## Teleport player from `self` to `_teleport_target` keeping the same relative
## transform
func _teleport_player() -> void:
    _player.global_transform = _get_relative_transform(
        _player.global_transform,
        global_transform,
        _teleport_target.global_transform,
    )
    player_teleported.emit()


## Set the shader param `VIEWPORT_SHADER_PARAM` to the viewport textures of
## `_renderers`
func _reset_viewport_shader_param() -> void:
    var viewport_textures: Array[ViewportTexture] = []
    for renderer in _renderers:
        viewport_textures.append(renderer.get_viewport_texture())

    _material.set_shader_parameter(
        VIEWPORT_SHADER_PARAM,
        viewport_textures,
    )


## Set the position of the portal oposite the player along the z-plane of this Node
func update_portal_pos() -> void:
    var current_frame_angle = global_basis.z.dot(global_position - _player.global_position)
    var current_direction_sign = signf(current_frame_angle)
    _mesh.position.z = current_direction_sign * _size.z / 4
    _recursion_mesh.position.z = _mesh.position.z


## Prepare this portal to be teleported to. [br]
## When teleporting into a `PortalBody`, this needs to be ran to
## prevent a flicker on the first frame after teleportation
func prepare_for_teleport() -> void:
    update_portal_pos()
    _renderers[0].use_oblique_frustum = false
    for renderer in _renderers:
        renderer.update_camera_position()


## Return `true` if the player is in the portal's `Area3D`
func is_player_in_portal() -> bool:
    return _player_in_portal


# FIXME: Make the meshes clickable to allow the user to move portals around
# more easily
# func _upate_editor_mesh() -> void:
#     if _editor_debug:
#         if _editor_mesh_0 != null:
#             _editor_mesh_0.queue_free()
#             _editor_mesh_0 = null
#             _editor_mesh_1.queue_free()
#             _editor_mesh_1 = null
#         return

#     if _editor_mesh_0 == null:
#         var material_0 = StandardMaterial3D.new()
#         material_0.albedo_color = EDITOR_DISPLAY_COLOR_0
#         material_0.albedo_color.a = EDITOR_DISPLAY_ALPHA
#         material_0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
#         material_0.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
#         _editor_mesh_0 = _create_mesh(material_0)

#         var material_1 = StandardMaterial3D.new()
#         material_1.albedo_color = EDITOR_DISPLAY_COLOR_1
#         material_1.albedo_color.a = EDITOR_DISPLAY_ALPHA
#         material_1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
#         material_1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
#         _editor_mesh_1 = _create_mesh(material_1)
#         await(_editor_mesh_1.ready)
#     else:
#         _editor_mesh_0.mesh.size = Vector3(_size.x, _size.y, _size.z / 2)
#         _editor_mesh_1.mesh.size = Vector3(_size.x, _size.y, _size.z / 2)

#     _editor_mesh_0.position.z = _size.z / 4
#     _editor_mesh_1.position.z = -1 * _size.z / 4


## Add generated children to scene for debugging. [br]
## NOTE: Make sure to turn off debug mode to delete these generated children.
# func _run_editor_debug() -> void:
#     _editor_debug = not _editor_debug

#     if _editor_debug:
#        _setup()
#     else:
#         for child in get_children():
#             if child in [_mesh, _area_3d, _vis_notifier, _recursion_mesh]:
#                 child.queue_free()

#     # _upate_editor_mesh()


# TODO: Docstring
func _get_relative_transform(
    target_node: Transform3D,
    target_ref: Transform3D,
    this_ref: Transform3D,
) -> Transform3D:
    var transform_offset = target_ref.affine_inverse() * target_node  # Get current relative to reference
    return this_ref * transform_offset  # Return new transform relativate to target
