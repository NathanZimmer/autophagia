@tool
class_name PortalPair extends PortalProcessor
## Automatically create `PortalRenderer` nodes for and setup the link between two
## `PortalBody` nodes. Handles linking to `n` child `PortalPair` nodes

# forward pass == first PortalBody child and its renderer, rendering down each branch of
# the scene tree
# back pass == second PortalBody child and its renderer, rendering up only this branch
# of the scene tree

signal back_pass_secondary_cam_updated
signal back_pass_cam_visibilty_changed

## Render layers to use for forward pass portal (first child) [br]
## NOTE: Will be overridden if parent is PortalPair, Overrides `_portal_render_layer`
@export_flags_2d_render var _forward_pass_render_layer: int = 32
## Render layers to use for back pass portal (second child)
## NOTE: Will be overridden if parent is PortalPair, Overrides `_portal_render_layer`
@export_flags_2d_render var _back_pass_render_layer: int = 128

var fp_portal: PortalBody
var fp_renderer: PortalRenderer
var bp_portal: PortalBody
var bp_renderer: PortalRenderer

var _child_pairs: Array[PortalPair]
## Map of child bp_portals and their cameras for setting bp_renderer secondary target
var _bp_secondary_targets: Dictionary[PortalBody, Camera3D]
var _pair_parent: PortalPair


func _setup(portals: Array[PortalBody]) -> void:
    super._setup(portals)

    fp_portal = portals[0]
    fp_renderer = fp_portal.get_renderers()[0]
    bp_portal = portals[1]
    bp_renderer = bp_portal.get_renderers()[0]
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
## `render_layers`: render layers to use for this node's portals. Passed in as
## `cull_mask` when called in children [br]
## `cull_mask`: cull mask for this node's cameras. Passed in as `render_layers` when
## called in children [br]
func ping_pong_layers(render_layers: int, cull_mask: int) -> void:
    fp_portal.render_layers = render_layers
    bp_portal.render_layers = render_layers

    fp_renderer.cull_mask = _world_render_layers & ~render_layers
    bp_renderer.cull_mask = _world_render_layers & ~render_layers
    if not _child_pairs.is_empty() or true:
        fp_renderer.cull_mask |= cull_mask
        bp_renderer.cull_mask |= cull_mask

    for pair in _child_pairs:
        pair.ping_pong_layers(cull_mask, render_layers)


## Recurse down the tree and set back pass viewport activation order. Activates root
## viewport first.
func set_viewport_activation_order() -> void:
    var sub_viewport := bp_renderer.get_sub_viewport()
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), false)
    RenderingServer.viewport_set_active(sub_viewport.get_viewport_rid(), true)

    for pair in _child_pairs:
        pair.set_viewport_activation_order()


## Recurse down the tree and set secondary cameras for forward pass and back pass
## renderers
func set_secondary_cameras() -> void:
    for pair in _child_pairs:
        pair.fp_renderer.secondary_target_cam = fp_renderer.camera
        _bp_secondary_targets[pair.bp_portal] = pair.bp_renderer.camera
        pair.set_secondary_cameras()


## Recurse down the tree and connect `portal_entered_screen` signals to set camera usage
## down the tree
func connect_screen_enter_signals() -> void:
    fp_portal.portal_entered_screen.connect(set_use_secondary_target.bind(false))
    bp_portal.portal_entered_screen.connect(set_secondary_cam_from_map.bind(false, null))
    for pair in _child_pairs:
        pair.connect_screen_enter_signals()


## Recurse down the tree and set special case camera usage signals for the frame that the
## player teleports
func connect_teleport_signals() -> void:
    fp_portal.player_teleported.connect(
        func() -> void:
            for pair in _child_pairs:
                pair.set_use_secondary_target(false)
    )
    bp_portal.player_teleported.connect(
        func() -> void:
            for pair in _child_pairs:
                pair.set_use_secondary_target(true)
    )
    for pair in _child_pairs:
        pair.fp_portal.player_teleported.connect(
            set_secondary_cam_from_map.bind(true, pair.bp_portal)
        )
        pair.bp_portal.player_teleported.connect(func() -> void: bp_renderer.set_target_cam(false))

        pair.back_pass_secondary_cam_updated.connect(set_secondary_cam_from_map)
        pair.connect_teleport_signals()


## Set Whether or not to use the secondary camera for the forward pass. Recurses down the
## tree with `use_secondary_target = True` [br]
## ## Parameters [br]
## `use_secondary_target`: Whether `fp_renderer` should use its secondary camera target
func set_use_secondary_target(use_secondary_target: bool) -> void:
    fp_renderer.set_target_cam(use_secondary_target)
    for pair in _child_pairs:
        pair.set_use_secondary_target(true)


## Set Whether or not to use the secondary camera for the back pass. Signals up the tree
## with `use_secondary_target = True, portal = self.bp_portal` [br]
## ## Parameters [br]
## `use_secondary_target`: Whether `bp_renderer` should use its secondary camera target [br]
## `portal`: The portal to use when indexing `_bp_secondary_targets`
func set_secondary_cam_from_map(use_secondary_target: bool, portal: PortalBody) -> void:
    bp_renderer.secondary_target_cam = _bp_secondary_targets.get(portal)
    bp_renderer.set_target_cam(use_secondary_target)
    back_pass_secondary_cam_updated.emit(true, bp_portal)


## Recurse down the tree and connect signals needed to enable/disable viewports
func connect_viewport_activation_signals() -> void:
    fp_portal.portal_entered_screen.connect(set_down_chain_viewports_active)
    fp_portal.portal_exited_screen.connect(set_down_chain_viewports_active)

    bp_portal.portal_entered_screen.connect(set_up_chain_viewports_active)
    bp_portal.portal_exited_screen.connect(set_up_chain_viewports_active)

    # Manually overriding these settings to prevent flicker
    fp_portal.player_teleported.connect(
        func() -> void:
            bp_renderer.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
    )
    bp_portal.player_teleported.connect(
        func() -> void:
            fp_renderer.get_sub_viewport().render_target_update_mode = (
                SubViewport.UPDATE_WHEN_PARENT_VISIBLE
            )
    )

    for pair in _child_pairs:
        pair.connect_viewport_activation_signals()
        pair.back_pass_cam_visibilty_changed.connect(set_up_chain_viewports_active)


## Set forward pass viewport active based on `fp_portal` visibility. Calls down the tree
## with `override_active` set based on `fp_portal` visibility [br]
## ## Parameters [br]
## `override_active`: Whether to override the results of `fp_portal.is_portal_on_screen()`
func set_down_chain_viewports_active(override_active := false) -> void:
    var active: bool = (
        override_active
        or fp_portal.is_portal_on_screen()
        or _pair_parent and _pair_parent.fp_portal_on_screen()
    )
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    fp_renderer.get_sub_viewport().render_target_update_mode = render_target_update_mode
    for pair in _child_pairs:
        pair.set_down_chain_viewports_active(active)


## Set back pass viewport active based on `bp_portal` visibility. Calls up the tree
## with `override_active` set based on `bp_portal` visibility [br]
## ## Parameters [br]
## `override_active`: Whether to override the results of `bp_portal.is_portal_on_screen()`
func set_up_chain_viewports_active(override_active: bool = false) -> void:
    var child_bp_portal_on_screen := _child_pairs.any(
        func(pair: PortalPair) -> bool: return pair.bp_portal.is_portal_on_screen()
    )
    var active: bool = (
        override_active
        or bp_portal.is_portal_on_screen()
        or child_bp_portal_on_screen
    )
    var render_target_update_mode := (
        SubViewport.UPDATE_WHEN_PARENT_VISIBLE if active else SubViewport.UPDATE_DISABLED
    )
    bp_renderer.get_sub_viewport().render_target_update_mode = render_target_update_mode

    back_pass_cam_visibilty_changed.emit(active)


## Returns `True` if the forward pass portal for this pair is on the screen
func fp_portal_on_screen() -> bool:
    return fp_portal.is_portal_on_screen()
