class_name Inventory extends Node
## Logic for positioning items in the inventory

const MAX_STACK_SIZE = 5

## Emit when inventory state changes
signal updated
## Emit with an ItemInfo when an item is used
# signal item_used

@export var _inventory_size: int
@export var _message_handler: MessageHandler

var _items: Array[ItemInfo] = []
var _count: Array[int] = []


func _ready() -> void:
    _items.resize(_inventory_size)
    _count.resize(_inventory_size)

    if _message_handler:
        _message_handler.item_received.connect(_on_item_received)


func _on_item_received(inventory_item: InventoryItem) -> void:
    var new_count := _add_item(inventory_item.item_info, inventory_item.count)
    if new_count != inventory_item.count:
        inventory_item.count = new_count
        updated.emit()


## Add an item to the first available index (first index with this item or first empty
## index if this item is not yet in the inventory). if `count` is higher than
##_`MAX_STACK_SIZE`, moves to next available index. [br]
## ## Parameters [br]
## `item`: The type of item to add [br]
## `count`: The number of that item to add [br]
## ## Returns [br]
## Number of items that couldn't be added to inventory
func _add_item(item: ItemInfo, count: int) -> int:
    var keys := range(_inventory_size)
    var remaining := count

    # Try to slot into existing stacks first
    var valid_indices := keys.filter(func(i: int) -> int: return _items[i] == item)
    for idx: int in valid_indices:
        remaining = _add_item_by_idx(item, idx, remaining)
        if not remaining:
            return 0

    # If there is still remaining, create new stacks
    valid_indices = keys.filter(func(i: int) -> int: return not _items[i])
    for idx: int in valid_indices:
        remaining = _add_item_by_idx(item, idx, remaining)
        if not remaining:
            return 0

    return remaining


## Add an item to the inventory at a specific index [br]
## ## Parameters [br]
## `item`: The type of item to add [br]
## `idx`: The inventory index to add to [br]
## `count`: The number of that item to add [br]
## ## Returns [br]
## Number of items that couldn't be added to inventory
func _add_item_by_idx(item: ItemInfo, idx: int, count: int) -> int:
    if idx > _inventory_size - 1:
        push_error(
            "Trying to index past inventory limit: idx=%d, limit=%d" % [idx, _inventory_size - 1]
        )
        return count

    if not _items[idx]:
        _items[idx] = item
        _count[idx] = 0
    elif _items[idx] != item:
        return count

    var new_count := _count[idx] + count
    if new_count > MAX_STACK_SIZE:
        _count[idx] = MAX_STACK_SIZE
        return new_count - MAX_STACK_SIZE

    _count[idx] = new_count
    return 0


# FIXME: This doesn't look at stack size at all, make it do that and maybe merge with
# _add_item_by_idx
## TODO
func adjust_count(idx: int, amount: int) -> bool:
    if idx > _inventory_size - 1:
        push_error(
            "Trying to index past inventory limit: idx=%d, limit=%d" % [idx, _inventory_size - 1]
        )
        return false
    var new_amount := _count[idx] + amount
    if new_amount < 0:
        push_error(
            (
                "Trying to decrement item below zero: idx=%d, count=%d, adjustment=%d"
                % [idx, _count[idx], amount]
            )
        )
        return true
    _count[idx] = new_amount
    if new_amount == 0:
        _items[idx] = null
    updated.emit()
    return new_amount == 0


# func _pop_item(idx: int) -> ItemInfo:
#     if not _items[idx]:
#         return null
#     if _count[idx] <= 0:
#         return null
#     _count[idx] -= 1
#     return _items[idx]

# ## TODO
# func use_item(idx: int) -> void:
#     var item := _pop_item(idx)
#     if item:
#         item_used.emit(item)

# ## TODO
# func drop_item(idx: int, count: int) -> void:
#     pass
#     # TODO: Create an item pickup at the feet of the player.
#     # Will need to disable opening of GUI while in air to make
#     # this logic easier.


func get_size() -> int:
    return _inventory_size


func item_at_idx(idx: int) -> ItemInfo:
    return _items[idx]


func count_at_idx(idx: int) -> int:
    return _count[idx]
