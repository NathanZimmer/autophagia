class_name InventoryItem extends RefCounted
## TODO

signal depleted

var item_info: ItemInfo
var count: int:
    set(value):
        if count == value:
            return
        count = value
        if count <= 0:
            depleted.emit()


func _init(item_info: ItemInfo = null, count: int = 0) -> void:
    self.item_info = item_info
    self.count = count
