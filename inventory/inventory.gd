class_name Inventory extends Node
## Logic for positioning items in the inventory

const INVENTORY_SIZE = 10
const MAX_STACK_SIZE = 5

@export var _message_handler: MessageHandler

# TODO: Refactor to use InventoryItem node instead of just info resource??
var _items: Array[ItemInfo] = []
var _count: Array[int] = []


func _ready() -> void:
    _items.resize(INVENTORY_SIZE)
    _count.resize(INVENTORY_SIZE)

    if _message_handler:
        _message_handler.item_received.connect(_on_item_received)


func _on_item_received(inventory_item: InventoryItem) -> void:
    inventory_item.count = _add_item(inventory_item.item_info, inventory_item.count)


## TODO
## Returns: Number of items that couldn't be added to inventory
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


## TODO
## Returns: Number of items that couldn't be added to inventory index
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
