class_name InventoryItem extends RefCounted
## An `ItemInfo` Resource and count. Emits `depleted` when count reaches 0

## Emited when count <= 0
signal depleted

var item_info: ItemInfo
var count: int:
    set(value):
        if count == value:
            return
        count = value
        if count <= 0:
            depleted.emit()
        if count < 0:
            printerr("%s count depleted below zero to %d" % [self, count])


func _init(item_info: ItemInfo = null, count: int = 0) -> void:
    self.item_info = item_info
    self.count = count
