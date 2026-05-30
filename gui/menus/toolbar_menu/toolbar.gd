class_name iToolbar extends HBoxContainer
## Menu for quick accessing `Inventory` indices from zero to toolbar size

## Max toolbar size the UI can support without scaling changes
const MAX_TOOLBAR_SIZE := 4

var InventoryIcon := preload("uid://c4b0a3scm2jlc")

var _inventory: Inventory
var _item_user: ItemUser

var _selected_index := 0

@onready var _toolbar_container: GridContainer = %ToolbarContainer


func _ready() -> void:
    _init_toolbar_container()
    _toolbar_container.get_child(0).select()


func _unhandled_input(event: InputEvent) -> void:
    if not Utils.verify_component(self, _inventory):
        return
    if not (event is InputEventKey or event is InputEventMouseButton):
        return
    if event.is_released():
        return

    if event.is_action_pressed(InputActions.Player.USE_ITEM):
        _use_selected_item()
        accept_event()
        return

    # Handle scrolling or swapping with number keys
    var new_index := -1
    if event is InputEventKey:
        var keycode: int = event.keycode - 49
        if keycode < _inventory.get_toolbar_size() and keycode >= 0:
            new_index = keycode

    if new_index == -1:
        if event.is_action_pressed(InputActions.Ui.NEXT):
            new_index = _selected_index + 1
        elif event.is_action_pressed(InputActions.Ui.PREV):
            new_index = _selected_index - 1
        else:
            return
        new_index = wrap(new_index, 0, _inventory.get_toolbar_size())

    if new_index == -1:
        return

    _toolbar_container.get_child(_selected_index).deselect()
    _selected_index = new_index
    _toolbar_container.get_child(new_index).select()

    accept_event()


## Call `_item_user.use_item` with the selected item. Removes one from inventory
func _use_selected_item() -> void:
    if not Utils.verify_component_list(self, [_inventory, _item_user]):
        return

    AudioManager.play_pressed()
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
    for _i: int in range(0, MAX_TOOLBAR_SIZE):
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
    if not Utils.verify_component(self, _inventory):
        return

    var icons: Array[iInventoryIcon]
    icons.assign(_toolbar_container.get_children())

    var toolbar_size := _inventory.get_toolbar_size()
    var next_index := 0
    for i: int in range(MAX_TOOLBAR_SIZE):
        if next_index < toolbar_size:
            var icon := icons[next_index]
            icon.set_used(true)
            var item := _inventory.get_item(next_index)
            if item.item_info and item.count > 0:
                icon.set_item(item.item_info, item.count)
            else:
                icon.clear_item()

            next_index += 1
        else:
            icons[i].set_used(false)


## set inventory component and updated GUI
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_toolbar_container)

    _inventory = inventory
    _inventory.updated.connect(_update_toolbar_container)
    _update_toolbar_container()


func set_item_user(item_user: ItemUser) -> void:
    _item_user = item_user
