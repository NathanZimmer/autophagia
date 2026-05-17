class_name iToolbar extends HBoxContainer
## TODO

# TODO: Reduce code duplication from inventory_menu

# TODO: Get rid of this when toolbar code is added
const TOOLBAR_SIZE := 4

var InventoryIcon := preload("uid://c4b0a3scm2jlc")

var _inventory: Inventory
var _item_user: ItemUser

## Map icons in GUI to corresponding indices in Inventory
var _icon_index_map: Dictionary[iInventoryIcon, int]
var _selected_icon: iInventoryIcon

@onready var _toolbar_container: GridContainer = %ToolbarContainer


func _ready() -> void:
    _init_toolbar_container()
    _selected_icon = _toolbar_container.get_child(0)
    _selected_icon._on_select()

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
    if not event is InputEventKey:
        return
    if event.is_released():
        return

    var keycode: int = event.keycode - 48
    if not (keycode <= TOOLBAR_SIZE and keycode > 0):
        return

    # TODO: Add option to use scroll wheel to change selected item
    _selected_icon.deselect()
    _selected_icon = _toolbar_container.get_child(keycode - 1)
    _selected_icon._on_select()
    accept_event()


## TODO
func _use_selected_item() -> void:
    var idx := _icon_index_map[_selected_icon]
    var item := _inventory.get_item(idx)
    var item_info := item.item_info

    if not item_info:
        return

    var used := _item_user.use_item(item_info, item.count)
    if not used:
        return

    _inventory.remove_count(idx, 1)
    # var remainder := _inventory.remove_count(idx, 1)


## Add `InventoryIcon` children to inventory container
func _init_toolbar_container() -> void:
    for i: int in range(0, TOOLBAR_SIZE):
        _add_icon(_toolbar_container, i)


## Adds an icon to the specified container [br]
## ## Parameters [br]
## `container`: Node to add `InventoryIcon` child to [br]
## `container_idx`: Index in this container to add to. This is added to `_icon_index_map`
## for later use
func _add_icon(container: Container, container_index: int) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    _icon_index_map[icon] = container_index
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
