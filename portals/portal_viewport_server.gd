extends Node
## Holds a pool of SubViewports and cameras. Handles activation order and
## allocation/deallocation

## Number of viewports to keep in warmpool
const _NUM_WARM_VIEWPORTS = 10
# TODO: Add supporty for this
## Additional allowed viewports.
const _EXTRA_VIEWPORTS = 5

var _viewport_use: Dictionary[PortalViewport, bool]


class PortalViewport:
    extends RefCounted
    ## TODO

    const _ENVIRONMENT_OVERRIDES: Dictionary[String, Variant] = {
        "tonemap_mode": Environment.TONE_MAPPER_LINEAR,
        "tonemap_exposure": 1.0,
    }
    const _SUB_VIEWPORT_PROP_IGNORE_LIST = ["owner", "canvas_transform"]

    ## TODO
    var viewport: SubViewport
    ## TODO
    var camera: Camera3D

    ## TODO
    func _init(
        viewport: SubViewport,
        camera: Camera3D,
        reference_camera: Camera3D,
    ) -> void:
        self.viewport = viewport
        self.camera = camera
        viewport.add_child(camera)

        camera.environment = reference_camera.environment.duplicate()
        camera.attributes = reference_camera.attributes.duplicate()
        camera.fov = reference_camera.fov
        var environment := camera.environment
        for key in _ENVIRONMENT_OVERRIDES:
            environment.set(key, _ENVIRONMENT_OVERRIDES[key])

        var reference_viewport := reference_camera.get_viewport()
        var properties := reference_viewport.get_property_list()
        for property in properties:
            var key: String = property["name"]
            var val: Variant = reference_viewport.get(key)
            if key not in _SUB_VIEWPORT_PROP_IGNORE_LIST or key not in viewport:
                viewport.set(key, val)

        viewport.size = reference_viewport.size
        viewport.use_occlusion_culling = false
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        viewport.audio_listener_enable_2d = false
        viewport.audio_listener_enable_3d = false
        viewport.gui_disable_input = true


var _portal_viewports: Array[PortalViewport]
var _main_viewport: Viewport


func _ready() -> void:
    pass
    var main_camera := PlayerInterface.get_camera()
    _main_viewport = main_camera.get_viewport()

    for i in range(_NUM_WARM_VIEWPORTS):
        _portal_viewports.append(PortalViewport.new(SubViewport.new(), Camera3D.new(), main_camera))
        _viewport_use[_portal_viewports[i]] = false


## Get `count` viewports. Viewports are returned in the order they will render in
func get_viewports(count: int) -> Array[PortalViewport]:
    var available_viewports := _portal_viewports.filter(
        func(portal_viewport: PortalViewport) -> bool:
            return not _viewport_use[portal_viewport]
    )
    if available_viewports.size() < count:
        push_error(
            "%d viewports requested, but only %d available" % [count, available_viewports.size()]
        )

    # Adjust viewport activation order
    var main_viewport_rid := _main_viewport.get_viewport_rid()
    RenderingServer.viewport_set_active(main_viewport_rid, false)
    for portal_viewport: PortalViewport in available_viewports.slice(0, count):
        _viewport_use[portal_viewport] = true
        var viewport_rid := portal_viewport.viewport.get_viewport_rid()
        RenderingServer.viewport_set_active(viewport_rid, false)
        RenderingServer.viewport_set_active(viewport_rid, true)
    RenderingServer.viewport_set_active(main_viewport_rid, true)

    return available_viewports.slice(0, count)
