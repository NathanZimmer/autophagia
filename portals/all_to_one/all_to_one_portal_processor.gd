@tool
## TODO
# FIXME: Figure out why the portals are flashing when the player enters and
# FIXME: Need to handle the oblique frustum setting better. All-to-one is showing that
# The original method doesn't work for all cases
# wtf is going on with the last portal
class_name AllToOnePortalProcessor extends PortalProcessor

var _main_portal: PortalBody

func _setup():
    _main_portal = portals[0]

    var main_renderer := PortalRenderer.init(
        target_cam,
        _main_portal,
        portals[1],
        forward_pass_render_layers | world_render_layers,
        true,
    )
    renderers.append(main_renderer)
    add_child(main_renderer)

    # Workaround for typed array issue
    var typed_renderer_array: Array[PortalRenderer] = [main_renderer]
    _main_portal.reset(
        size if override_portal_sizes else _main_portal.size,
        typed_renderer_array.duplicate(),
        portal_render_layer,
        0,
        collision_layer,
        collision_mask,
        vis_notifier_render_layers,
        portals[1],
        target_cam.get_parent(),
        true,
    )
    _main_portal.player_teleported.connect(_ready_teleport_target)


    for portal in portals.slice(1):
        var renderer := PortalRenderer.init(
            target_cam,
            portal,
            _main_portal,
            forward_pass_render_layers | world_render_layers,
            true,
        )
        renderers.append(renderer)
        add_child(renderer)

        # Workaround for typed array issue
        typed_renderer_array.clear()
        typed_renderer_array.assign([renderer])
        portal.reset(
            size if override_portal_sizes else portal.size,
            typed_renderer_array.duplicate(),
            portal_render_layer,
            0,
            collision_layer,
            collision_mask,
            vis_notifier_render_layers,
            _main_portal,
            target_cam.get_parent(),
            true,
        )

        portal.player_entered_portal.connect(func(): _main_portal.teleport_target = portal)
        portal.player_entered_portal.connect(func(): main_renderer._reference_node = portal)
        portal.player_teleported.connect(_main_portal.prepare_for_teleport)
        # portal.player_entered_portal.connect(_set_use_oblique_frustum.bind(portal))
        # portal.player_exited_portal.connect(_set_use_oblique_frustum.bind(portal))

        # setup_signals(
        #     renderer,
        #     main_renderer,
        #     portal,
        #     _main_portal,
        # )
#         portal.player_entered_portal.connect(_set_use_oblique_frustum)
#         portal.player_exited_portal.connect(_set_use_oblique_frustum)

func _ready_teleport_target():
    var target = _main_portal.teleport_target
    target.prepare_for_teleport()

# func _test(portal: PortalBody):
#     _main_portal.teleport_target = portal
#     _main_portal.portal_renderers[0]._reference_node = portal

# func _set_use_oblique_frustum():
#     var cur_paired_portal: PortalBody = _main_portal.teleport_target
#     var use_oblique = not (
#         _main_portal.is_player_in_portal() or cur_paired_portal.is_player_in_portal()
#     )
#     print(use_oblique)
#     _main_portal.portal_renderers[0].use_oblique_frustum = use_oblique
#     cur_paired_portal.portal_renderers[0].use_oblique_frustum = use_oblique
