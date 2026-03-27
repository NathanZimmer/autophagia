class_name iInventoryIcon extends Control
## TODO

## TODO
signal item_selected

const HOVER_COLOR = Color(1.0, 0.66, 0.66)

@onready var _name_label: Label = %NameLabel
@onready var _count_label: Label = %CountLabel
@onready var _icon_button: TextureButton = %IconButton

var _item: ItemInfo


func _ready() -> void:
    _icon_button.pressed.connect(_on_press)
    _icon_button.mouse_entered.connect(
        func() -> void: _icon_button.modulate = HOVER_COLOR
    )
    _icon_button.mouse_exited.connect(
        func() -> void: _icon_button.modulate = Color.WHITE
    )
    _on_depletion()


func _on_press() -> void:
    _icon_button.grab_focus()
    item_selected.emit(_item)


## TODO
func set_item(item: ItemInfo, count: int) -> void:
    _item = item
    _name_label.text = item.name
    _name_label.show()
    _count_label.text = str(count)
    _count_label.show()
    _icon_button.texture_normal = item.icon


## TODO
func _on_depletion() -> void:
    _name_label.hide()
    _count_label.hide()
    _icon_button.texture_normal = null
    _item = null
