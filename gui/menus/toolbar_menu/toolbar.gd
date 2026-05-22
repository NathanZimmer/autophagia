class_name iToolbar extends HBoxContainer
## TODO

# TODO: Reduce code duplication from inventory_menu

# TODO: Get rid of this when toolbar code is added
const TOOLBAR_SIZE := 4

var InventoryIcon := preload("uid://c4b0a3scm2jlc")

var _inventory: Inventory
var _item_user: ItemUser

var _selected_index := 0

@onready var _toolbar_container: GridContainer = %ToolbarContainer


func _ready() -> void:
    _init_toolbar_container()
    _toolbar_container.get_child(0)._on_select()

    await get_tree().process_frame
    if not _inventory:
        push_error("_inventory not defined")
    if not _item_user:
        push_error("_item_user not defined")


func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.is_action_pressed(InputActions.Player.USE_ITEM):
        _use_selected_item()
        accept_event()


func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey or event is InputEventMouseButton):
        return
    if event.is_released():
        return

    var new_index: int
    if event is InputEventMouseButton:
        if event.is_action_pressed("mw_up"):
            new_index = _selected_index + 1
        elif event.is_action_pressed("mw_down"):
            new_index = _selected_index - 1
        else:
            return
        new_index = wrap(new_index, 0, TOOLBAR_SIZE)
    else:
        var keycode: int = event.keycode - 49
        if not (keycode < TOOLBAR_SIZE and keycode >= 0):
            return
        new_index = keycode

    _toolbar_container.get_child(_selected_index).deselect()
    _selected_index = new_index
    _toolbar_container.get_child(new_index)._on_select()

    accept_event()


## TODO
func _use_selected_item() -> void:
    var item := _inventory.get_item(_selected_index)
    var item_info := item.item_info

    if not item_info:
        return

    var used := _item_user.use_item(item_info, item.count)
    if not used:
        return

    _inventory.remove_count(_selected_index, 1)
    # var remainder := _inventory.remove_count(idx, 1)


## Add `InventoryIcon` children to inventory container
func _init_toolbar_container() -> void:
    for _i: int in range(0, TOOLBAR_SIZE):
        _add_icon(_toolbar_container)


## Adds an icon to the specified container [br]
## ## Parameters [br]
## `container`: Node to add `InventoryIcon` child to [br]
func _add_icon(container: Container) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    # icon.item_selected.connect(_on_icon_selection)
    container.add_child(icon)


## Set the `ItemInfo` and count of each invetory icon from `_inventory`
func _update_toolbar_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_toolbar_container.get_children())
    for i: int in range(TOOLBAR_SIZE):
        var item := _inventory.get_item(i)
        if item.item_info and item.count > 0:
            icons[i].set_item(item.item_info, item.count)
        else:
            icons[i].clear_item()


## set inventory component and updated GUI
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_toolbar_container)

    _inventory = inventory
    _inventory.updated.connect(_update_toolbar_container)
    _update_toolbar_container()


func set_item_user(item_user: ItemUser) -> void:
    _item_user = item_user
