## Handle camera positioning and rendering of portal to a `ViewportTexture`
class_name PortalRenderer extends Node

const ENVIRONMENT_OVERRIDES = {
    "tonemap_mode": Environment.TONE_MAPPER_LINEAR,
    "tonemap_exposure": 1.0,
}
const OBLIQUE_OFFSET = 0.1
const OBLIQUE_FRUSTUM_ENABLED = true
# NOTE: Enabling the oblique frustum breaks the depth buffer. this
# is ok for now because we aren't using it for anything

@export_group("Reference Targets")
## Target to track the position of
@export var _target_cam: Camera3D
## Node to track _target_cam relative to
@export var _target_reference_node: Node3D
## Node to position this renderer's camera relative to
@export var _reference_node: Node3D
@export_group("Rendering")
## Cull maks for this renderer's camera
@export_flags_3d_render var _cull_mask := 1 :
    set(value):
        if value == _cull_mask:
            return
        _cull_mask = value

        if _camera != null:
            _camera.cull_mask = value

    get():
        return _cull_mask

var use_oblique_frustum: bool :
    set(value):
        _camera.use_oblique_frustum = value
    get():
        return _camera.use_oblique_frustum

var _camera: Camera3D
var _sub_viewport: SubViewport


func _ready() -> void:
    _setup()


func _physics_process(_delta) -> void:
    update_camera_position()


## Create new `PortalRenderer`.
## equivilant to calling `new()` and then `reset(...)` [br]
## ## Parameters [br]
## `target_cam`: Target to track the position of [br]
## `target_reference_node`: Node to track _target_cam relative to [br]
## `reference_node`: Node to position this renderer's camera relative to [br]
## `cull_mask`: Cull maks for this renderer's camera [br]
static func init(
    target_cam: Camera3D,
    target_reference_node: Node3D,
    reference_node: Node3D,
    cull_mask: int,
) -> PortalRenderer:
    var renderer = PortalRenderer.new()
    renderer.reset(
        target_cam, target_reference_node, reference_node, cull_mask
    )
    return renderer


## Reinitialize with a new set of parameters [br]
## ## Parameters [br]
## `target_cam`: Target to track the position of [br]
## `target_reference_node`: Node to track _target_cam relative to [br]
## `reference_node`: Node to position this renderer's camera relative to [br]
## `cull_mask`: Cull maks for this renderer's camera [br]
func reset(
    target_cam: Camera3D,
    target_reference_node: Node3D,
    reference_node: Node3D,
    cull_mask: int,
) -> void:
    _target_cam = target_cam
    _target_reference_node = target_reference_node
    _reference_node = reference_node
    _cull_mask = cull_mask

    _setup()


## Initialize `_camera` and `_sub_viewport`
func _setup():
    if is_instance_valid(_sub_viewport):
        _sub_viewport.queue_free()

    _camera = _create_camera()
    _sub_viewport = _create_sub_viewport()

    _sub_viewport.add_child(_camera)


## Create and configure the camera for this portal renderer.
## Does not add it as a child
func _create_camera() -> Camera3D:
    var camera = Camera3D.new()
    camera.environment = _target_cam.environment.duplicate()
    camera.attributes = _target_cam.attributes.duplicate()
    camera.fov = _target_cam.fov

    camera.cull_mask = _cull_mask
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


## Get the camera generated by this renderer
func get_camera() -> Camera3D:
    return _camera


## Get the viewport texture of this renderer's sub-viewport
func get_viewport_texture() -> ViewportTexture:
    return _sub_viewport.get_texture()


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
