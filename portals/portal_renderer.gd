class_name PortalRenderer extends Node
## Handle camera positioning and rendering of portal to a `ViewportTexture`

const _OBLIQUE_OFFSET = 0.1
const _OBLIQUE_FRUSTUM_ENABLED = true
# NOTE: Enabling the oblique frustum breaks the depth buffer. this
# is ok for now because we aren't using it for anything

@export_group("Reference Targets")
## Camera to follow relative position of
@export var _target_cam: TrackedCamera
## Node to follow _target_cam relative to
@export var _target_reference_node: Node3D
## Node to position this renderer's camera relative to
@export var _reference_node: Node3D
@export_group("Rendering")
## Cull maks for this renderer's camera
@export_flags_3d_render var cull_mask := 1:
    set(value):
        if value == cull_mask:
            return
        cull_mask = value

        if _camera != null:
            _camera.cull_mask = value

    get:
        return cull_mask

var use_oblique_frustum: bool:
    set(value):
        _camera.use_oblique_frustum = value
    get:
        return _camera.use_oblique_frustum

var _camera: Camera3D
var _sub_viewport: SubViewport


func _ready() -> void:
    _setup()
    _target_cam.transform_changed.connect(update_camera_position)


func _init(
    target_cam: Camera3D = null,
    target_reference_node: Node3D = null,
    reference_node: Node3D = null,
    cull_mask: int = -1,
    portal_viewport: PortalViewportServer.PortalViewport = null,
) -> void:
    if target_cam:
        _target_cam = target_cam
    if target_reference_node:
        _target_reference_node = target_reference_node
    if reference_node:
        _reference_node = reference_node
    if cull_mask >= 0:
        self.cull_mask = cull_mask
    if portal_viewport:
        _camera = portal_viewport.camera
        _sub_viewport = portal_viewport.viewport
        add_child(_sub_viewport)


## Reinitialize with a new set of parameters [br]
## ## Parameters [br]
## `target_cam`: Camera to copy configuration from [br]
## `target_reference_node`: Node to track _target_cam relative to [br]
## `reference_node`: Node to position this renderer's camera relative to [br]
## `cull_mask`: Cull maks for this renderer's camera [br]
func reset(
    target_cam: Camera3D,
    target_reference_node: Node3D,
    reference_node: Node3D,
    cull_mask: int,
    portal_viewport: PortalViewportServer.PortalViewport,
) -> void:
    _target_cam = target_cam
    _target_reference_node = target_reference_node
    _reference_node = reference_node
    self.cull_mask = cull_mask
    _camera = portal_viewport.camera
    _sub_viewport = portal_viewport.viewport

    _setup()


## Initialize `camera` and `_sub_viewport`
func _setup() -> void:
    _camera.cull_mask = cull_mask
    if _OBLIQUE_FRUSTUM_ENABLED:
        _camera.use_oblique_frustum = true
        _camera.oblique_normal = _reference_node.global_basis.z
        _camera.oblique_position = _reference_node.global_position
        _camera.oblique_offset = _OBLIQUE_OFFSET


## Update camera position based on [br]
## * `reference_transform` [br]
## * `_target_reference_node` [br]
## * `_reference_node` [br]
func update_camera_position(reference_transform: Transform3D) -> void:
    _camera.global_transform = (Utils.get_relative_transform(
        reference_transform,
        _target_reference_node.global_transform,
        _reference_node.global_transform
    ))
    _camera.orthonormalize()


## Get the viewport texture of this renderer's sub-viewport
func get_viewport_texture() -> ViewportTexture:
    return _sub_viewport.get_texture()


## Set reference node for this renderer's camera
func set_reference_node(node: Node3D) -> void:
    _reference_node = node
