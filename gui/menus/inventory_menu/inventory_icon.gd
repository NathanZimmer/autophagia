class_name iInventoryIcon extends Control
## TODO

## TODO
signal item_selected

enum SelectionMode { DEFAULT, MOVE_FROM, MOVE_TO }

const HOVER_COLOR = Color(1.0, 0.66, 0.66)

## What `Inventory` index this represents
var index: int = -1

@export var _overlay_color: Color
@export var _overlay_move_from_color: Color
@export var _overlay_move_to_color: Color

@onready var _name_label: Label = %NameLabel
@onready var _count_label: Label = %CountLabel
@onready var _icon_button: TextureButton = %IconButton
@onready var _selected_overlay: TextureRect = %SelectedOverlay

var _item: ItemInfo
var _selection_mode: SelectionMode


func _ready() -> void:
    _selected_overlay.material.set("shader_parameter/color", _overlay_color)

    _icon_button.pressed.connect(_on_select)
    _icon_button.mouse_entered.connect(func() -> void: _icon_button.modulate = HOVER_COLOR)
    _icon_button.mouse_exited.connect(func() -> void: _icon_button.modulate = Color.WHITE)
    _icon_button.mouse_entered.disconnect(AudioManager._play_hover)
    on_depletion()


func _on_select() -> void:
    # _icon_button.grab_focus()
    _selected_overlay.show()
    item_selected.emit(_item)
    # if _selection_mode == SelectionMode.DEFAULT:
    #     item_selected.emit(_item)
    # elif _selection_mode == SelectionMode.MOVE_TO:
    #     item_selected_for_move.emit(_item)


## TODO
func set_selection_mode(mode: SelectionMode) -> void:
    match mode:
        SelectionMode.MOVE_FROM:
            _selected_overlay.material.set("shader_parameter/color", _overlay_move_from_color)
        SelectionMode.MOVE_TO:
            _selected_overlay.material.set("shader_parameter/color", _overlay_move_to_color)
        _:
            _selected_overlay.material.set("shader_parameter/color", _overlay_color)
    _selection_mode = mode


func deselct() -> void:
    set_selection_mode(SelectionMode.DEFAULT)
    _selected_overlay.hide()


## TODO
func set_item(item: ItemInfo, count: int) -> void:
    _item = item
    _name_label.text = item.name
    _name_label.show()
    _count_label.text = str(count)
    _count_label.show()
    _icon_button.texture_normal = item.icon


## TODO
func on_depletion() -> void:
    _name_label.hide()
    _count_label.hide()
    _icon_button.texture_normal = null
    _item = null
