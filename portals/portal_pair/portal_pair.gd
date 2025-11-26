@tool
class_name PortalPair extends PortalProcessor
## TODO

signal back_pass_secondary_cam_updated
signal back_pass_cam_visibilty_changed

## TODO [br]
## NOTE: Will be overridden if parent is PortalPair, Overrides `_portal_render_layer`
@export_flags_2d_render var _forward_pass_render_layer: int = 32
## TODO [br]
## NOTE: Will be overridden if parent is PortalPair, Overrides `_portal_render_layer`
@export_flags_2d_render var _back_pass_render_layer: int = 128

var portal_0: PortalBody
var renderer_0: PortalRenderer
var portal_1: PortalBody
var renderer_1: PortalRenderer

var _child_pairs: Array[PortalPair]
## TODO
var _secondary_target_map: Dictionary[PortalBody, Camera3D]
## TODO
var _skip_next_fp_deactivation := false
## TODO
var _skip_next_bp_deactivation := false


func _setup(portals: Array[PortalBody]) -> void:
    super._setup(portals)

    portal_0 = portals[0]
    renderer_0 = portal_0.get_renderers()[0]
    portal_1 = portals[1]
    renderer_1 = portal_1.get_renderers()[0]
    _child_pairs.assign(find_children("*", "PortalPair", false))

    # Only want to start chain of commands if this is the root PortalPair
    if is_instance_of(get_parent(), PortalPair):
        return

    ping_pong_layers(_forward_pass_render_layer, _back_pass_render_layer)
    set_viewport_activation_order()
    set_secondary_cameras()
    connect_on_screen_enter()
    connect_teleport_signals()
    # TODO: Make viewport activation logic more robust and remove some of the edge case
    # conditionals
    connect_viewport_activation_signals()


## TODO
func ping_pong_layers(layers: int, next_layers: int) -> void:
    portal_0.render_layers = layers
    portal_1.render_layers = layers

    renderer_0.cull_mask = _world_render_layers & ~layers
    renderer_1.cull_mask = _world_render_layers & ~layers
    if not _child_pairs.is_empty() or true:
        renderer_0.cull_mask |= next_layers
        renderer_1.cull_mask |= next_layers

    for pair in _child_pairs:
        pair.ping_pong_layers(next_layers, layers)


## TODO
func set_viewport_activation_order() -> void:
    var sub_viewport := renderer_1.get_sub_viewport()
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), false)
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), true)

    for pair in _child_pairs:
        pair.set_viewport_activation_order()


## TODO
func set_secondary_cameras() -> void:
    for pair in _child_pairs:
        pair.renderer_0.secondary_target_cam = renderer_0.camera
        _secondary_target_map[pair.portal_1] = pair.renderer_1.camera
        pair.set_secondary_cameras()


## TODO
func connect_on_screen_enter() -> void:
    portal_0.portal_entered_screen.connect(set_use_secondary_target.bind(false))
    portal_1.portal_entered_screen.connect(set_secondary_cam_from_map.bind(false, null))
    for pair in _child_pairs:
        pair.connect_on_screen_enter()


## TODO
func connect_teleport_signals() -> void:
    portal_0.player_teleported.connect(
        func() -> void:
            for pair in _child_pairs:
                pair.set_use_secondary_target(false)
    )
    portal_1.player_teleported.connect(
        func() -> void:
            for pair in _child_pairs:
                pair.set_use_secondary_target(true)
    )
    for pair in _child_pairs:
        pair.portal_0.player_teleported.connect(
            set_secondary_cam_from_map.bind(true, pair.portal_1)
        )
        pair.portal_1.player_teleported.connect(func() -> void: renderer_1.set_target_cam(false))

        pair.back_pass_secondary_cam_updated.connect(set_secondary_cam_from_map)
        pair.connect_teleport_signals()


## TODO
func set_use_secondary_target(use_secondary_target: bool) -> void:
    renderer_0.set_target_cam(use_secondary_target)
    for pair in _child_pairs:
        pair.set_use_secondary_target(true)


## TODO
func set_secondary_cam_from_map(use_secondary_target: bool, portal: PortalBody) -> void:
    renderer_1.secondary_target_cam = _secondary_target_map.get(portal)
    renderer_1.set_target_cam(use_secondary_target)
    back_pass_secondary_cam_updated.emit(true, portal_1)


## TODO
func connect_viewport_activation_signals() -> void:
    portal_0.portal_entered_screen.connect(set_down_chain_viewports_active.bind(true))
    portal_0.portal_exited_screen.connect(set_down_chain_viewports_active.bind(false))

    portal_1.portal_entered_screen.connect(set_up_chain_viewports_active.bind(true))
    portal_1.portal_exited_screen.connect(set_up_chain_viewports_active.bind(false))

    # Special behavior for viewport enabling/disabling after teleport
    portal_0.player_teleported.connect(
        func() -> void:
            renderer_0.get_sub_viewport().render_target_update_mode = SubViewport.UPDATE_DISABLED
            renderer_1.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
            skip_next_fp_deactivation()
    )
    portal_1.player_teleported.connect(
        func() -> void:
            renderer_1.get_sub_viewport().render_target_update_mode = SubViewport.UPDATE_DISABLED
            renderer_0.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
            _skip_next_bp_deactivation = true
            for pair in _child_pairs:
                pair.skip_next_fp_deactivation()
    )

    for pair in _child_pairs:
        pair.connect_viewport_activation_signals()
        pair.back_pass_cam_visibilty_changed.connect(set_up_chain_viewports_active)
        pair.portal_0.player_teleported.connect(func() -> void: _skip_next_bp_deactivation = true)


## TODO
func set_down_chain_viewports_active(active: bool, override_skip := false) -> void:
    if _skip_next_fp_deactivation and not active and not override_skip:
        _skip_next_fp_deactivation = false
        return
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    renderer_0.get_sub_viewport().render_target_update_mode = render_target_update_mode
    for pair in _child_pairs:
        pair.set_down_chain_viewports_active(active, true)


## TODO
func set_up_chain_viewports_active(active: bool, override_skip := false) -> void:
    if _skip_next_bp_deactivation and not active and not override_skip:
        _skip_next_bp_deactivation = false
        return
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    renderer_1.get_sub_viewport().render_target_update_mode = render_target_update_mode
    back_pass_cam_visibilty_changed.emit(active, true)


## TODO
func skip_next_fp_deactivation() -> void:
    _skip_next_fp_deactivation = true
