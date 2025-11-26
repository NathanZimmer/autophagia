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
var _pair_parent: PortalPair


func _setup(portals: Array[PortalBody]) -> void:
    super._setup(portals)

    portal_0 = portals[0]
    renderer_0 = portal_0.get_renderers()[0]
    portal_1 = portals[1]
    renderer_1 = portal_1.get_renderers()[0]
    _child_pairs.assign(find_children("*", "PortalPair", false))

    # Only want to start chain of commands if this is the root PortalPair
    var parent := get_parent()
    if is_instance_of(parent, PortalPair):
        _pair_parent = parent as PortalPair
        return

    ping_pong_layers(_forward_pass_render_layer, _back_pass_render_layer)
    set_viewport_activation_order()
    set_secondary_cameras()
    connect_screen_enter_signals()
    connect_teleport_signals()
    connect_viewport_activation_signals()


## Recurse down the tree and set render layers and cull masks to such that each set of
## portals can see their parent and children, but not themselves [br]
## ## Parameters [br]
## `render_layers`: render layers to use for this Node's portals. Passed in as
## `cull_mask` when called in children [br]
## `cull_mask`: cull mask for this Node's cameras. Passed in as `render_layers` when
## called in children [br]
func ping_pong_layers(render_layers: int, cull_mask: int) -> void:
    portal_0.render_layers = render_layers
    portal_1.render_layers = render_layers

    renderer_0.cull_mask = _world_render_layers & ~render_layers
    renderer_1.cull_mask = _world_render_layers & ~render_layers
    if not _child_pairs.is_empty() or true:
        renderer_0.cull_mask |= cull_mask
        renderer_1.cull_mask |= cull_mask

    for pair in _child_pairs:
        pair.ping_pong_layers(cull_mask, render_layers)


## Recurse down the tree and set back pass viewport activation order. Activates root
## viewport first.
func set_viewport_activation_order() -> void:
    var sub_viewport := renderer_1.get_sub_viewport()
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), false)
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), true)

    for pair in _child_pairs:
        pair.set_viewport_activation_order()


## Recurse down the tree and set secondary cameras for forward pass and back pass
## renderers
func set_secondary_cameras() -> void:
    for pair in _child_pairs:
        pair.renderer_0.secondary_target_cam = renderer_0.camera
        _secondary_target_map[pair.portal_1] = pair.renderer_1.camera
        pair.set_secondary_cameras()


## Recurse down the tree and connect `portal_entered_screen` signals to set camera usage
## down the tree
func connect_screen_enter_signals() -> void:
    portal_0.portal_entered_screen.connect(set_use_secondary_target.bind(false))
    portal_1.portal_entered_screen.connect(set_secondary_cam_from_map.bind(false, null))
    for pair in _child_pairs:
        pair.connect_screen_enter_signals()


## Recurse down the tree and set special case camera usage signals for the frame that the
## player teleports
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


## Set Whether or not to use the secondary camera for the forward pass. Recurses down the
## tree with `use_secondary_target = True` [br]
## ## Parameters [br]
## `use_secondary_target`: Whether `renderer_0` should use its secondary camera target
func set_use_secondary_target(use_secondary_target: bool) -> void:
    renderer_0.set_target_cam(use_secondary_target)
    for pair in _child_pairs:
        pair.set_use_secondary_target(true)


## Set Whether or not to use the secondary camera for the back pass. Signals up the tree
## with `use_secondary_target = True, portal = self.portal_1` [br]
## ## Parameters [br]
## `use_secondary_target`: Whether `renderer_1` should use its secondary camera target [br]
## `portal`: The portal to use when indexing `_secondary_target_map`
func set_secondary_cam_from_map(use_secondary_target: bool, portal: PortalBody) -> void:
    renderer_1.secondary_target_cam = _secondary_target_map.get(portal)
    renderer_1.set_target_cam(use_secondary_target)
    back_pass_secondary_cam_updated.emit(true, portal_1)


## Recurse down the tree and connect signals needed to enable/disable viewports
func connect_viewport_activation_signals() -> void:
    portal_0.portal_entered_screen.connect(set_down_chain_viewports_active)
    portal_0.portal_exited_screen.connect(set_down_chain_viewports_active)

    portal_1.portal_entered_screen.connect(set_up_chain_viewports_active)
    portal_1.portal_exited_screen.connect(set_up_chain_viewports_active)

    # Manually overriding these settings to prevent flicker
    portal_0.player_teleported.connect(
        func() -> void:
            renderer_1.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
    )
    portal_1.player_teleported.connect(
        func() -> void:
            renderer_0.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
    )

    for pair in _child_pairs:
        pair.connect_viewport_activation_signals()
        pair.back_pass_cam_visibilty_changed.connect(set_up_chain_viewports_active)


## TODO
func set_down_chain_viewports_active(override_active :=false) -> void:
    var active: bool = (
        override_active
        or portal_0._portal_on_screen
        or _pair_parent and _pair_parent.fp_portal_on_screen()
    )
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    renderer_0.get_sub_viewport().render_target_update_mode = render_target_update_mode
    for pair in _child_pairs:
        pair.set_down_chain_viewports_active(active)


## TODO
func set_up_chain_viewports_active(override_active: bool = false) -> void:
    var child_portal_1_on_screen := _child_pairs.any(
        func(pair: PortalPair) -> bool: return pair.portal_1._portal_on_screen
    )
    var active: bool = (
        override_active
        or portal_1._portal_on_screen
        or child_portal_1_on_screen
    )
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    renderer_1.get_sub_viewport().render_target_update_mode = render_target_update_mode

    back_pass_cam_visibilty_changed.emit(active)


## Returns `True` if the forward pass portal for this pair is on the screen
func fp_portal_on_screen() -> bool:
    return portal_0._portal_on_screen
