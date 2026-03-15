class_name Inventory extends Node
## Logic for positioning items in the inventory

const INVENTORY_SIZE = 10
const MAX_STACK_SIZE = 5

var _items: Array[InventoryItem] = []
var _count: Array[int] = []


func _ready() -> void:
    _items.resize(INVENTORY_SIZE)
    _count.resize(INVENTORY_SIZE)


## TODO
## Returns: Number of items that couldn't be added to inventory
func add_item(item: InventoryItem, count: int) -> int:
    var keys := range(INVENTORY_SIZE)
    var remaining := count

    # Try to slot into existing stacks first
    var valid_indices := keys.filter(func(i: int) -> int: return _items[i] == item)
    for idx: int in valid_indices:
        remaining = add_item_by_idx(item, idx, remaining)
        if not remaining:
            return 0

    # If there is still remaining, create new stacks
    valid_indices = keys.filter(func(i: int) -> int: return not _items[i])
    for idx: int in valid_indices:
        remaining = add_item_by_idx(item, idx, remaining)
        if not remaining:
            return 0

    return remaining


## TODO
## Returns: Number of items that couldn't be added to inventory index
func add_item_by_idx(item: InventoryItem, idx: int, count: int) -> int:
    if idx > INVENTORY_SIZE - 1:
        push_error(
            "Trying to index past inventory limit: idx=%d, limit=%d" % [idx, INVENTORY_SIZE - 1]
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
