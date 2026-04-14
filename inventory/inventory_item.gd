class_name InventoryItem extends RefCounted
## An `ItemInfo` Resource and count. Emits `depleted` when count reaches 0

## Emitted when count <= 0
signal depleted

var item_info: ItemInfo
var count: int:
    set(value):
        if count == value:
            return
        if value <= 0 and count > 0:
            depleted.emit()
        count = value


func _init(item_info: ItemInfo = null, count: int = 0) -> void:
    self.item_info = item_info
    self.count = count


func reset(item_info: ItemInfo = null, count: int = 0) -> void:
    self.item_info = item_info
    self.count = count
