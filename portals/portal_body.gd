@tool
## Handle meshing and collision for a single portal. Needs a set of `PortalRenderer`s
## as children to display
class_name PortalBody extends Node3D

const MATERIAL_PATH = "uid://b3gfilq0wguq8"
const VIEWPORT_SHADER_PARAM = "viewport_textures"
const RECURSION_PASS_THROUGH_COLOR = Color.MAGENTA

@export_group("Portal Dimensions")
## Size of this portal
@export var size := Vector3.ONE :
    set(value):
        if value == size:
            return
        size = value

        if Engine.is_editor_hint():
            update_gizmos()

    get:
        return size

@export_group("Reference Targets")
## Teleport the player to this node on traveling through this portal
@export var teleport_target: Node3D
## The target for teleportation
@export var _player: PhysicsBody3D
@export_group("Rendering")
## Layers to render on
@export_flags_3d_render var _render_layers := 2 :
    set(value):
        if value == _render_layers:
            return
        _render_layers = value

        if _mesh != null:
            _mesh.layers = _render_layers

    get:
        return _render_layers

## Layers for the `VisibleOnScreenNotifier3D` to check on
@export_flags_3d_render var _vis_notifier_render_layers := 0 :
    set(value):
        if value == _vis_notifier_render_layers:
            return
        _vis_notifier_render_layers = value

        if _vis_notifier != null:
            _vis_notifier.layers = _vis_notifier_render_layers

    get:
        return _vis_notifier_render_layers

## Layers to render the secondary `Mesh` on. This can be used to indicate when
## this portal is seen through another portal it shouldn't be or for portal recursion
@export_flags_3d_render var _recursion_render_layers := 0 :
    set(value):
        if value == _recursion_render_layers:
            return
        _recursion_render_layers = value

        if _recursion_mesh != null:
            _recursion_mesh.layers = _render_layers

    get:
        return _recursion_render_layers

@export_group("Collision")
## Collision layers for this portal's Area3D
@export_flags_3d_physics var _collision_layers := 1 :
    set(value):
        if value == _collision_layers:
            return
        _collision_layers = value

        if _area_3d != null:
            _area_3d.collision_layer = _collision_layers

    get:
        return _collision_layers

## Collision mask for this portal's Area3D
@export_flags_3d_physics var _collision_mask := 1 :
    set(value):
        if value == _collision_mask:
            return
        _collision_mask = value

        if _area_3d != null:
            _area_3d.collision_mask = _collision_mask
    get:
        return _collision_mask

var _material: ShaderMaterial = preload(MATERIAL_PATH).duplicate()
var _mesh: MeshInstance3D
## `Mesh` for viewing this portal through another portal. Useful
## for debugging or portal recursion
var _recursion_mesh: MeshInstance3D
var _area_3d: Area3D
var _vis_notifier: VisibleOnScreenNotifier3D
var _renderers: Array[PortalRenderer]
var _player_in_portal := false
var _portal_on_screen := false
## Whether the player was on the front or back side of this node's
## z-plane for the last frame
var _player_direction_sign: float
var _player_teleported_last_frame := false

signal portal_entered_screen
signal portal_exited_screen
signal player_teleported
signal player_entered_portal
signal player_exited_portal


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _renderers.assign(find_children("*", "PortalRenderer", false))

    _setup()


func _physics_process(_0) -> void:
    if Engine.is_editor_hint():
        return

    var current_frame_angle = global_basis.z.dot(global_position - _player.camera.global_position)
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
## ## Parameters [br]
## `size`: Size of this portal [br]
## `renderers`: The `PortalRenderer`s to display on this node's `Mesh` [br]
##  [b]Note[/b]: `renderers` will be added to this node's children [br]
## `render_layers`: Layers to render on [br]
## `recursion_render_layers`: Layers to render the secondary `Mesh` on [br]
## `collision_layers`: Collision layers for this node's `Area3D` [br]
## `collision_mask`: Collision mask for this node's `Area3D` [br]
## `vis_notifier_render_layers`: Layers for the `VisibleOnScreenNotifier3D` to check on [br]
## `teleport_target`: Teleport the player to this node on traveling through this portal [br]
## `player`: The target for teleportation [br]
func reset(
    size: Vector3,
    renderers: Array[PortalRenderer],
    render_layers: int,
    recursion_render_layers: int,
    collision_layers: int,
    collision_mask: int,
    vis_notifier_render_layers: int,
    teleport_target: Node3D,
    player: PhysicsBody3D,
) -> void:
    self.size = size
    _renderers = renderers
    # for renderer in _renderers:
    #     add_child(renderer)
    _render_layers = render_layers
    _recursion_render_layers = recursion_render_layers
    _collision_layers = collision_layers
    _collision_mask = collision_mask
    _vis_notifier_render_layers = vis_notifier_render_layers
    self.teleport_target = teleport_target
    _player = player

    _setup()


## Instantiate `_mesh`, `_recursion_mesh`, `_area_3d`, and `_vis_notifier`. [br]
## Run setup on passed-in variables [br]
func _setup() -> void:
    if is_instance_valid(_mesh):
        _mesh.queue_free()
    if is_instance_valid(_recursion_mesh):
        _recursion_mesh.queue_free()
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
    recursion_pass_material.disable_fog = true
    _recursion_mesh = _create_mesh(recursion_pass_material)
    _recursion_mesh.layers = _recursion_render_layers

    if not _renderers.is_empty():
        player_entered_portal.connect(func(): _renderers[0].use_oblique_frustum = false)
        player_exited_portal.connect(func(): _renderers[0].use_oblique_frustum = true)
        _reset_viewport_shader_param()

    if  is_instance_valid(_player):
        var current_frame_angle = (
            0.0 if _player == null else global_basis.z.dot(global_position - _player.camera.global_position)
        )
        _player_direction_sign = signf(current_frame_angle)

    if teleport_target is PortalBody:
        player_teleported.connect(teleport_target.prepare_for_teleport)


## Create and configure the mesh for this portal. [br]
## [b]Note[/b]: This mesh is only half the depth of the mesh in the
## Editor.
func _create_mesh(mesh_material: Material) -> MeshInstance3D:
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(size.x, size.y, size.z / 2)
    box_mesh.material = mesh_material

    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = box_mesh
    mesh_instance.layers = _render_layers
    mesh_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED

    if not Engine.is_editor_hint():
        add_child(mesh_instance)
    mesh_instance.global_transform = global_transform

    return mesh_instance


## Create and configure the on-screen visibility notifier
## for this portal
func _create_visiblity_notifier() -> VisibleOnScreenNotifier3D:
    var vis_notifier = VisibleOnScreenNotifier3D.new()
    vis_notifier.layers = _vis_notifier_render_layers
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

    return vis_notifier


## Create and configure the Area3D for this portal
func _create_area_3d() -> Area3D:
    var area_3d = Area3D.new()
    area_3d.collision_layer = _collision_layers
    area_3d.collision_mask = _collision_mask

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

    return area_3d

## Teleport player from `self` to `teleport_target` keeping the same relative
## transform
func _teleport_player() -> void:
    var old_basis = _player.global_basis
    _player.global_transform = _get_relative_transform(
        _player.global_transform,
        global_transform,
        teleport_target.global_transform,
    )
    _player.up_direction = _player.global_basis.y
    _player.velocity = _player.global_basis * (old_basis.inverse() * _player.velocity)
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
    var current_frame_angle = global_basis.z.dot(global_position - _player.camera.global_position)
    var current_direction_sign = signf(current_frame_angle)
    _mesh.position.z = current_direction_sign * size.z / 4
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


## Transform `target` from `original_ref` into `new_ref` [br]
## ## Parameters [br]
## `target`: The global transform of interest [br]
## `original_ref`: The global reference transform to convert from [br]
## `new_ref`: The global reference transform to convert to [br]
## ## Returns [br]
## `new_transform`: The global transform of `target` rotated from
## `original_ref` into `new_ref` [br]
func _get_relative_transform(
    target: Transform3D,
    orignal_ref: Transform3D,
    new_ref: Transform3D,
) -> Transform3D:
    var transform_offset = orignal_ref.affine_inverse() * target  # Get offset to orignal reference
    return new_ref * transform_offset  # Apply offest to new reference
