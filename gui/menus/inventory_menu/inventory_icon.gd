class_name iInventoryIcon extends Control
## TODO

@onready var _name_label: Label = %NameLabel
@onready var _count_label: Label = %CountLabel
@onready var _icon_button: TextureButton = %IconButton


## TODO
func set_item(item: ItemInfo, count: int) -> void:
    _name_label.text = item.name
    _count_label.text = str(count)
    _icon_button.texture_normal = item.icon


## TODO
func _on_depletion() -> void:
    pass
