@tool
## Automatically create `PortalRenderer` nodes for and
## setup the link between any even number of `PortalBody` nodes. [br]
## Each portal will have a recursive view into its sibling portals
## in the order of the children in the node-tree. [br]
## Take the following tree: [br]
## RecursivePortalProcessor [br]
## * PortalBody [br]
## * PortalBody1 [br]
## * PortalBody2 [br]
## * PortalBody3 [br]
## `PortalBody` will have a view into `PortalBody2` and
## `PortalBody3` through `PortalBody1`. Basically, put portals that can
## "see" into each other next to each other.
class_name RecursivePortalProcessor extends PortalProcessor

@export_group("Rendering")
## TODO
@export var _self_recurse := false
## Render layers for the recursion mesh of the forward pass portals
@export_flags_3d_render var _forward_pass_render_layers := 4
## Render layers for the recursion mesh of the back pass portals
@export_flags_3d_render var _back_pass_render_layers := 8

# NOTE: Creating a new full-resolution viewport for every level of recursion is
# very wasteful of memory. We can get away with it here for 2 reasons:
# (1) this game is going to be running at a very low resolution, and
# (2) Godot does not currently allow manually rendering individual viewports, so we
# couldn't implement a better solution if we wanted to

const RECURSION_LIMIT := 10

# FIXME: The base renderer has a 1 frame delay
# FIXME: the second-level portal sometimes has visible seams

## Reset child PortalBody objects and create PortalRenderers for each portal
## and each level of recursion
func _setup() -> void:
    var portals: Array[PortalBody]
    portals.assign(find_children("*", "PortalBody", false) as Array[PortalBody])

    if portals.size() % 2 != 0:
        push_warning("Uneven number of PortalBody children. This node will not process.")
        return

    # Forward pass
    for i in range(0, portals.size(), 2):
        var portal := portals[i]

        portal.player_teleported.connect(portals[i + 1].prepare_for_teleport)

        var base_renderer := PortalRenderer.init(
            _target_cam,
            portal,
            portals[i + 1],
            (_forward_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
        )
        var portal_renderers: Array[PortalRenderer] = [base_renderer]
        portal.add_child(base_renderer)

        # Create recursive renderers
        var j := i + 2 if i + 2 < portals.size() else 0
        var recursion_level := 1
        while j < portals.size():
            var renderer := PortalRenderer.init(
                portal_renderers[-1].get_camera(),
                portals[j],
                portals[j + 1],
                (_forward_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
            )
            portal_renderers.append(renderer)
            portal.add_child(renderer)

            recursion_level += 1
            if recursion_level >= RECURSION_LIMIT:
                break
            j += 2
            if j >= portals.size() and _self_recurse:
                j = 0

        # for j in range(i + 2, portals.size(), 2):
        #     var renderer := PortalRenderer.init(
        #         portal_renderers[-1].get_camera(),
        #         portals[j],
        #         portals[j + 1],
        #         (_forward_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
        #     )
        #     portal_renderers.append(renderer)
        #     portal.add_child(renderer)

        portal.reset(
            _size if _override_portal_sizes else portal.size,
            portal_renderers,
            _portal_render_layer,
            _forward_pass_render_layers,
            _collision_layer,
            _collision_mask,
            _vis_notifier_layers,
            portals[i + 1],
            _target_cam.get_parent(),
        )

    # Backward pass
    for i in range(portals.size() - 1, 0, -2):
        var portal := portals[i]

        portal.player_teleported.connect(portals[i - 1].prepare_for_teleport)

        var base_renderer := PortalRenderer.init(
            _target_cam,
            portal,
            portals[i - 1],
            (_back_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
        )
        var portal_renderers: Array[PortalRenderer] = [base_renderer]
        portal.add_child(base_renderer)

        # Create recursive renderers
        var j := i - 2 if i - 2 >= 0 else portals.size() - 1
        var recursion_level := 0
        while j >= 0:
            var renderer := PortalRenderer.init(
                portal_renderers[-1].get_camera(),
                portals[j],
                portals[j - 1],
                (_back_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
            )
            portal_renderers.append(renderer)
            portal.add_child(renderer)
            recursion_level += 1
            if recursion_level >= RECURSION_LIMIT:
                break
            j -= 2
            if j < 0 and _self_recurse:
                j = portals.size() - 1

        # for j in range(i - 2, 0, -2):
        #     var renderer := PortalRenderer.init(
        #         portal_renderers[-1].get_camera(),
        #         portals[j],
        #         portals[j - 1],
        #         (_back_pass_render_layers | _world_render_layers) & ~_portal_render_layer,
        #     )
        #     portal_renderers.append(renderer)
        #     portal.add_child(renderer)

        portal.reset(
            _size if _override_portal_sizes else portal.size,
            portal_renderers,
            _portal_render_layer,
            _back_pass_render_layers,
            _collision_layer,
            _collision_mask,
            _vis_notifier_layers,
            portals[i - 1],
            _target_cam.get_parent(),
        )


## Show warning if we don't have % 2 portal children
func _get_configuration_warnings() -> PackedStringArray:
    var portals = find_children("*", "PortalBody", false)

    var warnings: PackedStringArray = []
    if portals.size() % 2 != 0:
        warnings.append("This node needs an even number of PortalBody children to process.")

    return warnings
