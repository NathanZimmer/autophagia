@tool
## TODO
class_name PortalProcessor extends Node3D

const OBLIQUE_FRUSTUM_ENABLED = true

@export_group("Portal Dimensions")
## TODO
@export var override_portal_sizes := false :
    set(value):
        if value == override_portal_sizes:
            return
        override_portal_sizes = value

        if Engine.is_editor_hint() and override_portal_sizes:
            for portal in find_children("*", "PortalBody", false):
                portal.size = size

    get():
        return override_portal_sizes

## TODO
@export var size := Vector3.ONE :
    set(value):
        if value == size:
            return
        size = value

        if Engine.is_editor_hint() and override_portal_sizes:
            for portal in find_children("*", "PortalBody", false):
                portal.size = size

    get():
        return size

@export_group("Reference Target")
@export var target_cam: Camera3D

@export_group("Rendering")
## TODO
@export_flags_3d_render var world_render_layers := 1
## TODO
@export_flags_3d_render var portal_render_layer := 2
## TODO
@export_flags_3d_render var forward_pass_render_layers := 4
## TODO
@export_flags_3d_render var back_pass_render_layers := 8
## TODO
@export_flags_3d_render var vis_notifier_render_layers := 0

@export_group("Collision")
## TODO
@export_flags_3d_physics var collision_layer := 1
## TODO
@export_flags_3d_physics var collision_mask := 1

var portals: Array[PortalBody]
var renderers: Array[PortalRenderer]


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    if target_cam == null:
        target_cam = get_viewport().get_camera_3d()

    portals.assign(find_children("*", "PortalBody", false))
    _setup()


# func _physics_process(_delta) -> void:
#     if Engine.is_editor_hint():
#         return

#     for portal in portals:
#         portal.process()

#     for renderer in renderers:
#         renderer.update_camera_position()


# TODO
func _setup() -> void:
    # Forward pass
    for i in range(0, portals.size(), 2):
        var portal := portals[i]

        portal.player_teleported.connect(portals[i + 1].prepare_for_teleport)
        # portal.player_entered_portal.connect(_set_use_oblique_frustum.bind(portal))
        # portal.player_exited_portal.connect(_set_use_oblique_frustum.bind(portal))

        var base_renderer := PortalRenderer.init(
            target_cam,
            portal,
            portals[i + 1],
            forward_pass_render_layers | world_render_layers,
            true,
        )
        var portal_renderers: Array[PortalRenderer]
        portal_renderers.append(base_renderer)
        renderers.append(base_renderer)
        add_child(base_renderer)

        # Create recursive renderers
        var last_cam := base_renderer._camera
        for j in range(i + 2, portals.size(), 2):
            var renderer := PortalRenderer.init(
                last_cam,
                portals[j],
                portals[j + 1],
                forward_pass_render_layers | world_render_layers,
                true,
            )
            portal_renderers.append(renderer)
            renderers.append(renderer)
            add_child(renderer)
            last_cam = renderer._camera

        portal.reset(
            size if override_portal_sizes else portal.size,
            portal_renderers,
            portal_render_layer,
            forward_pass_render_layers,
            collision_layer,
            collision_mask,
            vis_notifier_render_layers,
            portals[i + 1],
            target_cam.get_parent(),
            true
        )

    # Backward pass
    for i in range(portals.size() - 1, 0, -2):
        var portal := portals[i]

        portal.player_teleported.connect(portals[i - 1].prepare_for_teleport)

        var base_renderer := PortalRenderer.init(
            target_cam,
            portal,
            portals[i - 1],
            back_pass_render_layers | world_render_layers,
            true,
        )
        var portal_renderers: Array[PortalRenderer]
        portal_renderers.append(base_renderer)
        renderers.append(base_renderer)
        add_child(base_renderer)

        # Create recursive renderers
        var last_cam := base_renderer._camera
        for j in range(i - 2, 0, -2):
            var renderer := PortalRenderer.init(
                last_cam,
                portals[j],
                portals[j - 1],
                back_pass_render_layers | world_render_layers,
                true
            )
            portal_renderers.append(renderer)
            renderers.append(renderer)
            add_child(renderer)
            last_cam = renderer._camera

        portal.reset(
            size if override_portal_sizes else portal.size,
            portal_renderers,
            portal_render_layer,
            back_pass_render_layers,
            collision_layer,
            collision_mask,
            vis_notifier_render_layers,
            portals[i - 1],
            target_cam.get_parent(),
            true
        )

    # for i in range(0, portals.size(), 2):
    #     setup_signals(
    #         portals[i].portal_renderers[0],
    #         portals[i + 1].portal_renderers[0],
    #         portals[i],
    #         portals[i + 1],
    #     )


# TODO: Make this better and test as replacement for manual processing
# func _ready_teleport_target(sending_portal: PortalBody):
#     var receiving_portal: PortalBody = sending_portal.teleport_target
#     receiving_portal.flip_portal_pos()
#     receiving_portal.portal_renderers[0].use_oblique_frustum = false
#     for renderer in receiving_portal.portal_renderers:
#         renderer.update_camera_position()


# func _set_use_oblique_frustum(sending_portal: PortalBody):
#     for renderer in sending_portal.portal_renderers:
#         renderer.use_oblique_frustum = not sending_portal._player_in_portal

    # sending_portal.portal_renderers[0].use_oblique_frustum = not sending_portal._player_in_portal
    # var receiving_portal: PortalBody = sending_portal.teleport_target
    # receiving_portal.portal_renderers[0].use_oblique_frustum = not sending_portal._player_in_portal

    # if (sending_portal._player_in_portal):
    #     print('sending_portal')
    #     print(sending_portal)
    #     print(sending_portal.portal_renderers[0].use_oblique_frustum)
    # else:
    #     print('receiving_portal')
    #     print(receiving_portal)
    #     print(receiving_portal.portal_renderers[0].use_oblique_frustum)


    # var receiving_portal: PortalBody = sending_portal.teleport_target
    # var use_oblique = not (sending_portal._player_in_portal or receiving_portal._player_in_portal)
    # sending_portal.portal_renderers[0].use_oblique_frustum = use_oblique
    # receiving_portal.portal_renderers[0].use_oblique_frustum = use_oblique


## TODO
# static func setup_signals(
#     renderer_0: PortalRenderer,
#     renderer_1: PortalRenderer,
#     portal_0: PortalBody,
#     portal_1: PortalBody,
# ) -> void:
#     portal_0.player_teleported.connect(renderer_1.update_camera_position)
#     portal_0.player_teleported.connect(portal_1.flip_portal_pos)
#     portal_1.player_teleported.connect(renderer_0.update_camera_position)
#     portal_1.player_teleported.connect(portal_0.flip_portal_pos)

#     if OBLIQUE_FRUSTUM_ENABLED:
#         var set_use_oblique_frustum = func():
#             var use_oblique = not (portal_0.is_player_in_portal() or portal_1.is_player_in_portal())
#             renderer_0.use_oblique_frustum = use_oblique
#             renderer_1.use_oblique_frustum = use_oblique

#         portal_0.player_entered_portal.connect(set_use_oblique_frustum)
#         portal_0.player_exited_portal.connect(set_use_oblique_frustum)

#         portal_1.player_entered_portal.connect(set_use_oblique_frustum)
#         portal_1.player_exited_portal.connect(set_use_oblique_frustum)
