class_name iInventoryIcon extends Control
## TODO

## TODO
signal item_selected

enum SelectionMode { DEFAULT, MOVE }

const HOVER_COLOR = Color(1.0, 0.66, 0.66)

@export var _overlay_color: Color
@export var _overlay_move_color: Color

## What `Inventory` index this represents
var index: int = -1  # TODO: Remove this from icon class and store somewhere elsee

var _item: ItemInfo
var _selection_mode: SelectionMode

@onready var _name_label: Label = %NameLabel
@onready var _count_label: Label = %CountLabel
@onready var _icon_button: TextureButton = %IconButton
@onready var _selected_overlay: TextureRect = %SelectedOverlay


func _ready() -> void:
    _selected_overlay.material.set("shader_parameter/color", _overlay_color)

    _icon_button.pressed.connect(_on_select)
    _icon_button.mouse_entered.connect(func() -> void: _icon_button.modulate = HOVER_COLOR)
    _icon_button.mouse_exited.connect(func() -> void: _icon_button.modulate = Color.WHITE)
    _icon_button.mouse_entered.disconnect(AudioManager._play_hover)
    clear_item()


func _on_select() -> void:
    # _icon_button.grab_focus()
    _selected_overlay.show()
    item_selected.emit(self)


## TODO
func set_selection_mode(mode: SelectionMode) -> void:
    match mode:
        SelectionMode.MOVE:
            _selected_overlay.material.set("shader_parameter/color", _overlay_move_color)
        _:
            _selected_overlay.material.set("shader_parameter/color", _overlay_color)
    _selection_mode = mode


func deselect() -> void:
    set_selection_mode(SelectionMode.DEFAULT)
    _selected_overlay.hide()


## TODO
func set_item(item_info: ItemInfo, count: int) -> void:
    _item = item_info
    _name_label.text = item_info.name
    _name_label.show()
    _count_label.text = str(count)
    _count_label.show()
    _icon_button.texture_normal = item_info.icon


func get_item() -> ItemInfo:
    return _item


## TODO
func clear_item() -> void:
    _name_label.hide()
    _count_label.hide()
    _icon_button.texture_normal = null

    _item = null
    _name_label.text = "None"
    _count_label.text = "None"
