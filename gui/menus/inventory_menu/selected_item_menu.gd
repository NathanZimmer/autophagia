class_name iSelectedItemMenu extends VBoxContainer
## TODO

## TODO
signal use_button_pressed
## TODO
signal move_button_pressed
## TODO
signal drop_button_pressed

const NO_ITEM_SELECTED_TEXT = "[select an item]"

@onready var _item_model: MeshInstance3D = %ItemModel

@onready var _use_button: Button = %UseButton
@onready var _move_button: Button = %MoveButton
@onready var _drop_button: Button = %DropButton

@onready var _name_label: Label = %NameLabel
@onready var _desc_label: Label = %DescLabel


func _ready() -> void:
    clear()

    _use_button.pressed.connect(use_button_pressed.emit)
    _move_button.pressed.connect(move_button_pressed.emit)
    _drop_button.pressed.connect(drop_button_pressed.emit)


## TODO
func clear() -> void:
    _item_model.hide()

    _use_button.hide()
    _move_button.hide()
    _drop_button.hide()

    _name_label.hide()
    _desc_label.text = NO_ITEM_SELECTED_TEXT
    _desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## TODO
func _reset() -> void:
    _item_model.show()

    _use_button.show()
    _move_button.show()
    _drop_button.show()

    _name_label.show()
    _desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func set_buttons_disabled(disabled: bool) -> void:
    _use_button.disabled = disabled
    _move_button.disabled = disabled
    _drop_button.disabled = disabled


## TODO
func set_item(item: ItemInfo) -> void:
    _use_button.grab_focus()
    if not item:
        clear()
        return

    _reset()
    _item_model.mesh = item.mesh
    _name_label.text = item.name
    _desc_label.text = item.description
