class_name ItemUser extends Node
## Handle usage of inventory items. Emits signals for local (player) changes and calls
## global message handlers for global changes. When spawning objects, creates them as
## siblings to `owner`

## Emit to adjust player temperature component
signal temp_adjusted(amount: int)
## Emit to adjust player hunger component
signal hunger_adjusted(amount: int)

const PICKUP_SPAWN_OFFSET := Vector3(0, -1, 0)
const PICKUP_SPAWN_RANGE := Vector3(0.25, 0, 0.25)

const ITEM_SPAWN_OFFSET := Vector3(0, 0.4, 0)
const ITEM_SPAWN_DISTANCE := -1

var Pickup := preload("uid://u87ws5522ov")


func _test_spawn_ball(count: int, test_inp: String) -> bool:
    print(count, test_inp)

    var sphere_mesh := SphereMesh.new()
    sphere_mesh.radius = 0.25
    sphere_mesh.height = 0.5
    # sphere_mesh.material = PlaceholderMaterial.new()
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = sphere_mesh

    # TODO: Determine how we should spawn objects. If we want to spawn them directly in
    # front of the player, we will need the camera forward vector
    owner.get_parent().add_child(mesh_instance)
    mesh_instance.global_position = (
        owner.global_position + ITEM_SPAWN_OFFSET + owner.global_basis.z * ITEM_SPAWN_DISTANCE
    )
    return true


func _test(count: int, test_inp: String) -> bool:
    print(count, test_inp)
    return true


## Call function from `item_info.function` with arguments `item_info.args` for each `count` [br]
## ## Returns [br]
## Whether or not the items are sucessfully used
func use_item(item_info: ItemInfo, count: int) -> bool:
    var args := [count] + item_info.args
    var arg_count := get_method_argument_count(item_info.function)
    var provided_count := args.size()
    if arg_count != provided_count:
        push_error(
            (
                "Argument count for function does not match size of provided arguments: "
                + "arg_count=%d, provided_count=%d" % [arg_count, provided_count]
            )
        )
        return false

    return callv(item_info.function, args)


## Create item pickup with `ItemInfo` and `count`
func drop_item(item_info: ItemInfo, count: int) -> void:
    var item_pickup: ItemPickup = Pickup.instantiate()
    owner.get_parent().add_child(item_pickup)
    item_pickup.reset(item_info, count, true)

    item_pickup.global_position = (
        owner.global_position
        + PICKUP_SPAWN_OFFSET
        + Vector3(
            randf_range(PICKUP_SPAWN_RANGE.x / -2, PICKUP_SPAWN_RANGE.x / 2),
            randf_range(PICKUP_SPAWN_RANGE.y / -2, PICKUP_SPAWN_RANGE.y / 2),
            randf_range(PICKUP_SPAWN_RANGE.z / -2, PICKUP_SPAWN_RANGE.z / 2),
        )
    )
