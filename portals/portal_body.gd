@tool
## TODO
class_name PortalBody extends Node3D

const MATERIAL_PATH = "uid://b3gfilq0wguq8"
const VIEWPORT_SHADER_PARAM = "viewport_textures"
const RECURSION_PASS_THROUGH_COLOR = Color.MAGENTA
const EDITOR_DISPLAY_COLOR_0 = Color.BLUE
const EDITOR_DISPLAY_COLOR_1 = Color.ORANGE
const EDITOR_DISPLAY_ALPHA = 0.25

@export_tool_button("Enable/Disable editor debug", "Callable") var debug = _run_editor_debug

@export_group("Portal Dimensions")
## TODO
@export var size := Vector3.ONE :
    set(value):
        if value == size:
            return
        size = value

        if Engine.is_editor_hint():
            # _upate_editor_mesh()
            pass

    get():
        return size

@export_group("Reference Targets")
## TODO
@export var teleport_target: Node3D
## TODO
@export var player: PhysicsBody3D
@export_group("Rendering")
## TODO
@export var portal_renderers: Array[PortalRenderer]
## TODO
@export_flags_3d_render var render_layers := 2 :
    set(value):
        if value == render_layers:
            return
        render_layers = value

        if not Engine.is_editor_hint() and _mesh != null:
            _mesh.layers = render_layers

    get():
        return render_layers

## TODO
@export_flags_3d_render var vis_notifier_render_layers := 0 :
    set(value):
        if value == vis_notifier_render_layers:
            return
        vis_notifier_render_layers = value

        if not Engine.is_editor_hint() and _vis_notifier != null:
            _vis_notifier.layers = vis_notifier_render_layers

    get():
        return vis_notifier_render_layers

## TODO
@export_flags_3d_render var recursion_render_layers := 0 :
    set(value):
        if value == recursion_render_layers:
            return
        recursion_render_layers = value

        if not Engine.is_editor_hint() and _recursion_mesh != null:
            _recursion_mesh.layers = render_layers

    get():
        return recursion_render_layers

@export_group("Collision")
## TODO
@export_flags_3d_physics var collision_layer := 1 :
    set(value):
        if value == collision_layer:
            return
        collision_layer = value

        if not Engine.is_editor_hint() and _area_3d != null:
            _area_3d.collision_layer = collision_layer

    get():
        return collision_layer

## TODO
@export_flags_3d_physics var collision_mask := 1 :
    set(value):
        if value == collision_mask:
            return
        collision_mask = value

        if not Engine.is_editor_hint() and _area_3d != null:
            _area_3d.collision_mask = collision_mask

    get():
        return collision_mask


var _material: ShaderMaterial = preload(MATERIAL_PATH).duplicate()
var _mesh: MeshInstance3D
## TODO: Explain this
var _recursion_mesh: MeshInstance3D
var _area_3d: Area3D
var _vis_notifier: VisibleOnScreenNotifier3D

var _player_in_portal := false
var _portal_on_screen := false

## Whether the player was on the positive or negative side of this
## portal in the last frame. Result of calling `signf()`
var _player_direction_sign: float
## TODO
var _player_teleported_last_frame := false

var _editor_debug = false
var _editor_mesh_0: MeshInstance3D = null
var _editor_mesh_1: MeshInstance3D = null

var _process_self := true

signal portal_entered_screen
signal portal_exited_screen
signal player_teleported
signal player_entered_portal
signal player_exited_portal


func _ready() -> void:
    if Engine.is_editor_hint():
        # _upate_editor_mesh()
        return
    if get_parent() is PortalProcessor or not _process_self:
        return

    # if teleport_target is PortalBody:
    #     PortalProcessor.setup_signals(
    #         portal_renderers[0],
    #         teleport_target.portal_renderers[0],
    #         self,
    #         teleport_target,
    #     )

    _setup()


func _physics_process(_delta) -> void:
    if Engine.is_editor_hint() or not _process_self:
        return

    process()


# TODO: Docstring
func reset(
    new_size: Vector3,
    new_portal_renderers: Array[PortalRenderer],
    new_render_layers: int,
    new_recursion_render_layers: int,
    new_collision_layer: int,
    new_collision_mask: int,
    new_vis_notifier_render_layers: int,
    new_teleport_target: Node3D,
    new_player: PhysicsBody3D,
    new_process_self: bool
) -> void:
    size = new_size
    portal_renderers = new_portal_renderers
    render_layers = new_render_layers
    recursion_render_layers = new_recursion_render_layers
    collision_layer = new_collision_layer
    collision_mask = new_collision_mask
    vis_notifier_render_layers = new_vis_notifier_render_layers
    teleport_target = new_teleport_target
    player = new_player
    _process_self = new_process_self

    _setup()


func _setup() -> void:
    if is_instance_valid(_mesh):
        _mesh.queue_free()
    if is_instance_valid(_area_3d):
        _area_3d.queue_free()
    if is_instance_valid(_vis_notifier):
        _vis_notifier.queue_free()

    _mesh = _create_mesh(_material)
    _area_3d = _create_area_3d()
    _vis_notifier = _create_visiblity_notifier()

    var recursion_pass_material = StandardMaterial3D.new()
    recursion_pass_material.albedo_color = RECURSION_PASS_THROUGH_COLOR
    recursion_pass_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _recursion_mesh = _create_mesh(recursion_pass_material)
    _recursion_mesh.layers = recursion_render_layers

    _reset_viewport_shader_param()
    var current_frame_angle = global_basis.z.dot(global_position - player.global_position)
    _player_direction_sign = signf(current_frame_angle)

    player_entered_portal.connect(func(): portal_renderers[0].use_oblique_frustum = false)
    player_exited_portal.connect(func(): portal_renderers[0].use_oblique_frustum = true)

    if teleport_target is PortalBody:
        player_teleported.connect(teleport_target.prepare_for_teleport)


# TODO
func process() -> void:
    var current_frame_angle = global_basis.z.dot(global_position - player.global_position)
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
        # FIXME: This breaks portal recursion if the receiving portals are placed
        # "before" the sending portals
        flip_portal_pos()
        _player_teleported_last_frame = false

    _player_direction_sign = current_direction_sign


## Create and configure the mesh for this portal. [br]
## NOTE: This mesh is only half the depth of the mesh in the
## Editor.
func _create_mesh(mesh_material: Material) -> MeshInstance3D:
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(size.x, size.y, size.z / 2)
    box_mesh.material = mesh_material

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = box_mesh
    mesh_instance.layers = render_layers
    mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

    if not Engine.is_editor_hint():
        add_child(mesh_instance)
    mesh_instance.global_transform = global_transform

    if _editor_debug:
        mesh_instance.owner = get_tree().edited_scene_root
    return mesh_instance


## Create and configure the on-screen visibility notifier
## for this portal
func _create_visiblity_notifier() -> VisibleOnScreenNotifier3D:
    var vis_notifier = VisibleOnScreenNotifier3D.new()
    vis_notifier.layers = vis_notifier_render_layers
    add_child(vis_notifier)
    vis_notifier.aabb = AABB(size / -2, size)

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

    if _editor_debug:
        vis_notifier.owner = get_tree().edited_scene_root
    return vis_notifier


## Create and configure the Area3D for this portal
func _create_area_3d() -> Area3D:
    var area_3d = Area3D.new()
    area_3d.collision_layer = collision_layer
    area_3d.collision_mask = collision_mask

    var collider = CollisionShape3D.new()
    collider.shape = BoxShape3D.new()
    collider.shape.size = size

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

    if _editor_debug:
        area_3d.owner = get_tree().edited_scene_root
        collider.owner = get_tree().edited_scene_root
    return area_3d


## Teleport player from `self` to `teleport_target` keeping the same relative
## transform
func _teleport_player() -> void:
    player.global_transform = _get_relative_transform(
        player.global_transform,
        global_transform,
        teleport_target.global_transform,
    )
    player_teleported.emit()


## TODO
func _reset_viewport_shader_param() -> void:
    var viewport_textures: Array[ViewportTexture] = []
    for renderer in portal_renderers:
        viewport_textures.append(renderer.get_viewport_texture())

    _material.set_shader_parameter(
        VIEWPORT_SHADER_PARAM,
        viewport_textures,
    )


# FIXME: Don't always flip because sometimes it's already on the correct side
# NOTE: A related issue, portal recusion doesn't work if a receiving portal is
# not "behind" the sending portal. Maybe rework the portal repositioning.
## TODO
func flip_portal_pos() -> void:
    var current_frame_angle = global_basis.z.dot(global_position - player.global_position)
    var current_direction_sign = signf(current_frame_angle)
    _mesh.position.z = current_direction_sign * size.z / 4
    _recursion_mesh.position.z = _mesh.position.z


## Prepare this portal to be teleported to. [br]
## When teleporting into a `PortalBody`, this needs to be ran to
## prevent a flicker on the first frame after teleportation
func prepare_for_teleport() -> void:
    flip_portal_pos()
    portal_renderers[0].use_oblique_frustum = false
    for renderer in portal_renderers:
        renderer.update_camera_position()


## TODO
func is_player_in_portal() -> bool:
    return _player_in_portal


# FIXME: Make the meshes clickable to allow the user to move portals around
# more easily
func _upate_editor_mesh() -> void:
    if _editor_debug:
        if _editor_mesh_0 != null:
            _editor_mesh_0.queue_free()
            _editor_mesh_0 = null
            _editor_mesh_1.queue_free()
            _editor_mesh_1 = null
        return

    if _editor_mesh_0 == null:
        var material_0 = StandardMaterial3D.new()
        material_0.albedo_color = EDITOR_DISPLAY_COLOR_0
        material_0.albedo_color.a = EDITOR_DISPLAY_ALPHA
        material_0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material_0.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _editor_mesh_0 = _create_mesh(material_0)

        var material_1 = StandardMaterial3D.new()
        material_1.albedo_color = EDITOR_DISPLAY_COLOR_1
        material_1.albedo_color.a = EDITOR_DISPLAY_ALPHA
        material_1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        material_1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        _editor_mesh_1 = _create_mesh(material_1)
        await(_editor_mesh_1.ready)
    else:
        _editor_mesh_0.mesh.size = Vector3(size.x, size.y, size.z / 2)
        _editor_mesh_1.mesh.size = Vector3(size.x, size.y, size.z / 2)

    _editor_mesh_0.position.z = size.z / 4
    _editor_mesh_1.position.z = -1 * size.z / 4


## Add generated children to scene for debugging. [br]
## NOTE: Make sure to turn off debug mode to delete these generated children.
func _run_editor_debug() -> void:
    _editor_debug = not _editor_debug

    if _editor_debug:
       _setup()
    else:
        for child in get_children():
            if child in [_mesh, _area_3d, _vis_notifier, _recursion_mesh]:
                child.queue_free()

    _upate_editor_mesh()


# TODO: Docstring
func _get_relative_transform(
    target_node: Transform3D,
    target_ref: Transform3D,
    this_ref: Transform3D,
) -> Transform3D:
    var transform_offset = target_ref.affine_inverse() * target_node  # Get current relative to reference
    return this_ref * transform_offset  # Return new transform relativate to target
