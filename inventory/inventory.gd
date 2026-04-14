class_name Inventory extends Node
## Logic for positioning items in the inventory

## Emit when inventory state changes
signal updated

const MAX_STACK_SIZE = 5

@export var _inventory_size: int
@export var _message_handler: MessageHandler

var _items: Array[InventoryItem]


func _ready() -> void:
    _items.resize(_inventory_size)
    for i in range(_inventory_size):
        _items[i] = InventoryItem.new()

    if _message_handler:
        _message_handler.item_received.connect(_on_item_received)


func _on_item_received(item: InventoryItem) -> void:
    var remainder := _add_item(item)
    if remainder != item.count:
        # Is there a better way to communicate this count change than
        # using item as an in-out var?
        item.count = remainder


## Add an item to the first available index (first index with this item or first empty
## index). if `item.count` is higher than _`MAX_STACK_SIZE`, moves to next available
## index.[br]
## ## Parameters [br]
## `item`: The type of item to add [br]
## ## Returns [br]
## Count that couldn't be added to inventory
func _add_item(item: InventoryItem) -> int:
    var keys := range(_inventory_size)
    var remainder := item.count

    # Try to slot into existing stacks first
    var valid_indices := keys.filter(
        func(i: int) -> int: return _items[i].item_info == item.item_info
    )
    for idx: int in valid_indices:
        remainder = adjust_count(idx, remainder)
        if not remainder:
            return 0

    # If there is still remaining, create new stacks
    valid_indices = keys.filter(func(i: int) -> int: return not _items[i].item_info)
    for idx: int in valid_indices:
        remainder = add_new_item(idx, item.item_info, remainder)
        if not remainder:
            return 0

    return remainder


## Add/subtract count to an item to the inventory at a specific index [br]
## ## Parameters [br]
## `idx`: The inventory index to add to [br]
## `count`: The number of that item to add/subtract [br]
## ## Returns [br]
## Remainder of items if `count` is positive and `_MAX_STACK_SIZE` is reached, else 0
func adjust_count(idx: int, count: int) -> int:
    var item := _items[idx]
    var new_count := item.count + count
    if new_count < 0:
        push_error(
            (
                "Trying to decrement item below zero: idx=%d, count=%d, adjustment=%d"
                % [idx, item.count, count]
            )
        )
        return 0
    if new_count > MAX_STACK_SIZE:
        item.count = MAX_STACK_SIZE
        updated.emit()
        return new_count - MAX_STACK_SIZE

    item.count = new_count
    if new_count == 0:
        item.reset()

    updated.emit()
    return 0


## Update Index to new `ItemInfo` and count [br]
## ## Paramters [br]
## `idx`: The inventory index to add to [br]
## `item_info`: The new item type [br]
## `count`: The number of that item to add [br]
## ## Returns [br]
## Number of items that couldn't be added to inventory
func add_new_item(idx: int, item_info: ItemInfo, count: int) -> int:
    var item := _items[idx]
    if item.item_info:
        push_warning(
            (
                "Adding new item to index that is not null. idx=%d, count=%d, adjustment=%d"
                % [idx, item.count, count]
            )
        )
    item.reset(item_info, 0)
    return adjust_count(idx, count)


func get_size() -> int:
    return _inventory_size


func get_item(idx: int) -> InventoryItem:
    return _items[idx]
