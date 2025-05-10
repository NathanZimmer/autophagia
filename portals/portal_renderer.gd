@tool
## TODO
class_name PortalRenderer extends Node

const ENVIRONMENT_OVERRIDES = {
    "tonemap_mode": Environment.TONE_MAPPER_LINEAR,
    "tonemap_exposure": 1.0,
}
const OBLIQUE_OFFSET = 0.1
const OBLIQUE_FRUSTUM_ENABLED = true

@export_tool_button("Enable/Disable editor debug", "Callable") var debug = _run_editor_debug

@export_group("Reference Targets")
## Target to track the transform of
@export var _target_cam: Camera3D
## Node to get the target camera transform relative to
@export var _target_reference_node: Node3D
## Node to set this renderer's camera transform relative to
@export var _reference_node: Node3D
@export_group("Rendering")
## Cull maks for this renderer's camera
@export_flags_3d_render var cull_mask = 1 :
    set(value):
        if value == cull_mask:
            return
        cull_mask = value

        if not Engine.is_editor_hint() and _camera != null:
            _camera.cull_mask = value

    get():
        return cull_mask

var use_oblique_frustum: bool :
    set(value):
        _camera.use_oblique_frustum = value
    get():
        return _camera.use_oblique_frustum

var _camera: Camera3D
var _sub_viewport: SubViewport

var _editor_debug = false
var _process_self := true


func _ready() -> void:
    if Engine.is_editor_hint() or not _process_self:
        return

    _setup()


## TODO
static func init(
    new_target_cam: Camera3D,
    new_target_reference_node: Node3D,
    new_reference_node: Node3D,
    new_cull_mask: int,
    new_process_self: bool,
) -> PortalRenderer:
    var pr = PortalRenderer.new()
    pr.reset(
        new_target_cam,
        new_target_reference_node,
        new_reference_node,
        new_cull_mask,
        new_process_self,
    )
    return pr


# TODO: Docstring
func reset(
    new_target_cam: Camera3D,
    new_target_reference_node: Node3D,
    new_reference_node: Node3D,
    new_cull_mask: int,
    new_process_self: bool,
):
    _target_cam = new_target_cam
    _target_reference_node = new_target_reference_node
    _reference_node = new_reference_node
    cull_mask = new_cull_mask
    _process_self = new_process_self

    _setup()


func _setup():
    _camera = _create_camera()
    _sub_viewport = _create_sub_viewport()

    _sub_viewport.add_child(_camera)


func _process(_delta) -> void:
    if Engine.is_editor_hint() or not _process_self:
        return

    update_camera_position()


## Add generated children to scene for debugging. [br]
## NOTE: Make sure to turn off debug mode to delete these generated children.
func _run_editor_debug() -> void:
    _editor_debug = not _editor_debug

    if _editor_debug:
        _setup()

        _sub_viewport.owner = get_tree().edited_scene_root
        _camera.owner = get_tree().edited_scene_root
    else:
        for child in get_children():
            if child == _sub_viewport:
                child.queue_free()


## Create and configure the camera for this portal renderer.
## Does not add it as a child
func _create_camera() -> Camera3D:
    var camera = Camera3D.new()
    camera.environment = _target_cam.environment.duplicate()
    camera.attributes = _target_cam.attributes.duplicate()
    camera.fov = _target_cam.fov

    camera.cull_mask = cull_mask
    if OBLIQUE_FRUSTUM_ENABLED:
        camera.use_oblique_frustum = true
        camera.oblique_normal = _reference_node.global_basis.z
        camera.oblique_position = _reference_node.global_position
        camera.oblique_offset = OBLIQUE_OFFSET

    for key in ENVIRONMENT_OVERRIDES:
        var value = ENVIRONMENT_OVERRIDES[key]
        camera.environment.set(key, value)

    return camera


# FIXME: Viewport configuration is off from the main viewport,
# but I'm not sure where
## Create and cofigure the SubViewport for this portal renderer.
## Adds it as a child.
func _create_sub_viewport() -> SubViewport:
    var sub_viewport = SubViewport.new()
    var target_viewport = _target_cam.get_viewport()

    add_child(sub_viewport)

    # FIXME: Condition "!viewport->canvas_map.has(p_canvas)" is true.
    var properties = target_viewport.get_property_list()
    for property in properties:
        var key = property['name']
        var val = target_viewport.get(key)
        sub_viewport.set(key, val)

    sub_viewport.size = Vector2i(
        ProjectSettings.get_setting("display/window/size/viewport_width"),
        ProjectSettings.get_setting("display/window/size/viewport_height")
    )
    sub_viewport.use_occlusion_culling = false
    sub_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
    sub_viewport.handle_input_locally = true

    return sub_viewport


## Update camera position based on [br]
## * `_target_cam` [br]
## * `_target_reference_node` [br]
## * `_reference_node` [br]
func update_camera_position() -> void:
    _camera.global_transform = _get_relative_transform(
        _target_cam.global_transform,
        _target_reference_node.global_transform,
        _reference_node.global_transform,
    )
    _camera.orthonormalize()


# TODO: Docstring
func _get_relative_transform(
    target_node: Transform3D,
    target_ref: Transform3D,
    this_ref: Transform3D,
) -> Transform3D:
    var transform_offset = target_ref.affine_inverse() * target_node  # Get current relative to reference
    return this_ref * transform_offset  # Return new transform relativate to target


## Get the camera generated by this renderer
func get_camera() -> Camera3D:
    return _camera


## Get the viewport texture of this renderer's sub-viewport
func get_viewport_texture() -> ViewportTexture:
    return _sub_viewport.get_texture()
