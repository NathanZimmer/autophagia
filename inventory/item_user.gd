class_name ItemUser extends Node
## Handle usage of inventory items. Emits signals for local (player) changes and calls
## global message handlers for global changes. When spawning objects, creates them as
## siblings to `owner`

# TODO: Implement skeleton for "using" items

## Emit to adjust player temperature component
signal temp_adjusted(amount: int)
## Emit to adjust player hunger component
signal hunger_adjusted(amount: int)

const PICKUP_SPAWN_OFFSET := Vector3(0, -1, 0)
const PICKUP_SPAWN_RANGE := Vector3(0.25, 0, 0.25)

var Pickup := preload("uid://u87ws5522ov")


func test(count: int, test_inp: String) -> bool:
    print(count, test_inp)
    return true


## TODO
func use_item(item_info: ItemInfo, count: int) -> bool:
    var args := [count] + item_info.args
    return callv(item_info.function, args)


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
