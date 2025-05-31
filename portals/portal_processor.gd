@tool
## Automatically create `PortalRenderer` objects for and
## setup the link between two `PortalBody` objects
class_name PortalProcessor extends Node3D

@export_group("Portal Dimensions")
## Whether or not to override the size of all `PortalBody`
## children
@export var _override_portal_sizes := false :
    set(value):
        if value == _override_portal_sizes:
            return
        _override_portal_sizes = value

        if Engine.is_editor_hint() and _override_portal_sizes:
            for portal in find_children("*", "PortalBody", false):
                portal.size = _size

    get():
        return _override_portal_sizes

## Portal size override, only used if `_override_portal_sizes == true`
@export var _size := Vector3.ONE :
    set(value):
        if value == _size:
            return
        _size = value

        if Engine.is_editor_hint() and _override_portal_sizes:
            for portal in find_children("*", "PortalBody", false):
                portal.size = _size

    get():
        return _size

@export_group("Reference Target")
## Target to track the position of. If left blank, will use the base
## viewport's `Camera3D`
@export var _target_cam: Camera3D

@export_group("Rendering")
## Render layers for the `PortalRenderer` cameras
@export_flags_3d_render var _world_render_layers := 1
## Layers to render the `PortalBody`s on
@export_flags_3d_render var _portal_render_layer := 2
## Layers for the `VisibleOnScreenNotifier3D`s to check on
@export_flags_3d_render var _vis_notifier_layers := 0

@export_group("Collision")
## Collision layers for all portals
@export_flags_3d_physics var _collision_layer := 1
## Collision mask for all portals
@export_flags_3d_physics var _collision_mask := 1


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    if _target_cam == null:
        _target_cam = get_viewport().get_camera_3d()

    _setup()


## Reset child PortalBody objects and create PortalRenderers for each
func _setup() -> void:
    var portals = find_children("*", "PortalBody", false)
    if portals.size() != 2:
        push_warning(
            "Incorrect number of PortalBody children. This node will not process."
        )
        return

    var portal_0: PortalBody = portals[0]
    var portal_1: PortalBody = portals[1]

    var renderer_0 := PortalRenderer.init(
        _target_cam,
        portal_0,
        portal_1,
        _world_render_layers & ~_portal_render_layer,
    )

    var renderer_1 := PortalRenderer.init(
        _target_cam,
        portal_1,
        portal_0,
        _world_render_layers & ~_portal_render_layer,
    )

    portal_0.reset(
        _size if _override_portal_sizes else portal_0.size,
        [renderer_0] as Array[PortalRenderer],
        _portal_render_layer,
        0,
        _collision_layer,
        _collision_mask,
        _vis_notifier_layers,
        portal_1,
        _target_cam.get_parent(),
    )

    portal_1.reset(
        _size if _override_portal_sizes else portal_1.size,
        [renderer_1] as Array[PortalRenderer],
        _portal_render_layer,
        0,
        _collision_layer,
        _collision_mask,
        _vis_notifier_layers,
        portal_0,
        _target_cam.get_parent(),
    )


## Show warning if we don't have 2 portal children
func _get_configuration_warnings() -> PackedStringArray:
    var portals = find_children("*", "PortalBody", false)

    var warnings: PackedStringArray = []
    if portals.size() != 2:
        warnings.append("This node needs two PortalBody children to process.")

    return warnings
