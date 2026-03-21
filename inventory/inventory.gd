class_name Inventory extends Node
## Logic for positioning items in the inventory

const INVENTORY_SIZE = 10
const MAX_STACK_SIZE = 5

@export var _message_handler: MessageHandler

var _items: Array[ItemInfo] = []
var _count: Array[int] = []


func _ready() -> void:
    _items.resize(INVENTORY_SIZE)
    _count.resize(INVENTORY_SIZE)

    if _message_handler:
        _message_handler.item_received.connect(_on_item_received)


func _on_item_received(inventory_item: InventoryItem) -> void:
    inventory_item.count = _add_item(inventory_item.item_info, inventory_item.count)


## Add an item to the first available index (first index with this item or first empty
## index if this item is not yet in the inventory). if `count` is higher than
##_`MAX_STACK_SIZE`, moves to next available index. [br]
## ## Parameters [br]
## `item`: The type of item to add [br]
## `count`: The number of that item to add [br]
## ## Returns [br]
## Number of items that couldn't be added to inventory
func _add_item(item: ItemInfo, count: int) -> int:
    var keys := range(INVENTORY_SIZE)
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
