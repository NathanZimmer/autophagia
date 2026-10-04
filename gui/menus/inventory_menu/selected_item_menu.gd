class_name iSelectedItemMenu extends VBoxContainer
## Menu for the selected item. Shows model, name, and description. Has buttons for using
## dropping, and moving this item.

# FIXME: Figure out best way to manage the vertex snap shader. I.e. 320x240 vs 96x60
# FIXME: Update this to enable/disable its buttons and GUI based on whether it has an item set

## Emit when the use button is pressed.
signal use_button_pressed

## Emit when the move button is pressed.
signal move_button_pressed

## Emit when the drop button is pressed.
signal drop_button_pressed

enum MenuContext { INVENTORY, CHEST }

## Text to display in place of the item desc when no item is selected
const NO_ITEM_SELECTED_TEXT = "[select an item]"
## Text to display in place of the move button text during "move mode"
const ALT_MOVE_TEXT = "Cancel"

var _move_mode := false
var _default_move_text: String
var _context := MenuContext.INVENTORY

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
    _default_move_text = _move_button.text


## Clears the menu and hides all elements.
func clear() -> void:
    _item_model.hide()

    _use_button.disabled = true
    _move_button.disabled = true
    _drop_button.disabled = true

    _name_label.hide()
    _desc_label.text = NO_ITEM_SELECTED_TEXT
    _desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Toggle move mode (AKA, toggle move button behavior)
func toggle_move_mode() -> void:
    _move_mode = not _move_mode
    _move_button.text = ALT_MOVE_TEXT if _move_mode else _default_move_text


## Set the item to be displayed in the menu. If null, hides/disables menu elements and shows
## "select an item" message
func set_item(item: ItemInfo) -> void:
    if not item:
        clear()
        return

    _use_button.grab_focus()
    _item_model.show()

    _use_button.disabled = _context == MenuContext.CHEST
    _move_button.disabled = false
    _drop_button.disabled = _context == MenuContext.CHEST

    _name_label.show()
    _desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _item_model.mesh = item.mesh
    _name_label.text = item.name
    _desc_label.text = item.description


## Set context for this menu between regular inventory mode and chest interaction mode
func set_context(context: MenuContext) -> void:
    _context = context
