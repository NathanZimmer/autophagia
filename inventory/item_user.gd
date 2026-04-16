class_name ItemUser extends Node
## Handle usage of inventory items. Emits signals for local (player) changes and calls
## global message handlers for global changes. When spawning objects, creates them as
## siblings to `owner`

## TODO
signal temp_adjusted(amount: int)
## TODO
signal hunger_adjusted(amount: int)


func test(count: int, test_inp: String) -> bool:
    print(count, test_inp)
    return true


## TODO
func use_item(item_info: ItemInfo, count: int) -> bool:
    var args := [count] + item_info.args
    return callv(item_info.function, args)
