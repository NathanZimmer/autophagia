class_name iInventoryMenu extends iMenuControl
## TODO
# TODO: Make the subviewport container work

# TODO:
# - Add support for moving items, using items, and dropping items
# - Add support for moving items between inventory and containers

# Item Moving:
# - Untangle mess of if-elses. Find better design, refactor. Add better state handling
#   or something
# - Fix or remove separate selection highlight color for move mode
# - Fix moving items to/from containers
# - Logic is spread out between menu, icon, and inventory. Fix that

# TODO: Get rid of this when toolbar code is added
const TOOLBAR_SIZE := 4

const MAX_CONTAINER_SIZE := 5
const MAX_INVENTORY_SIZE := 12

var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory
var _container: Inventory

var _selected_icon: iInventoryIcon

var _move_mode := false
var _move_mode_icon: iInventoryIcon

@onready var _inventory_container: GridContainer = %InventoryContainer
@onready var _toolbar_container: GridContainer = %ToolbarContainer
@onready var _selected_item_menu: iSelectedItemMenu = %SelectedItemMenu
@onready var _count_popup: iCountPopup = %CountPopup

@onready var _container_panel: Panel = %ContainerPanel
@onready var _container_container: GridContainer = %ContainerContainer


func _ready() -> void:
    super._ready()
    menu_exited.connect(_on_exit)

    _selected_item_menu.use_button_pressed.connect(_use_selected_item)
    _selected_item_menu.drop_button_pressed.connect(_drop_selected_item)
    _selected_item_menu.move_button_pressed.connect(_start_move_mode)

    _init_inventory_container()
    _init_container_container()


func _shortcut_input(event: InputEvent) -> void:
    # super._shortcut_input(event)
    if event is InputEventKey:
        if (
            event.is_action_pressed(InputActions.UI.INVENTORY)
            or event.is_action_pressed(InputActions.UI.CANCEL)
        ):
            if _move_mode:
                _move_mode = false
                _end_move_mode()
            else:
                menu_exited.emit()
            accept_event()
        elif event.is_action_pressed(InputActions.UI.JOURNAL):
            accept_event()


func _init_inventory_container() -> void:
    for i: int in range(0, TOOLBAR_SIZE):
        _add_icon(_toolbar_container, i)
    for i: int in range(TOOLBAR_SIZE, MAX_INVENTORY_SIZE):
        _add_icon(_inventory_container, i)


func _init_container_container() -> void:
    for i: int in range(0, MAX_CONTAINER_SIZE):
        _add_icon(_container_container, i)


func _add_icon(container: Container, container_index: int) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    icon.index = container_index  # TODO: Move this to a map or something
    icon.item_selected.connect(_on_icon_selection)
    container.add_child(icon)


func _on_exit() -> void:
    if _selected_icon:
        _selected_icon.deselect()
        _selected_icon = null
    _selected_item_menu.clear()
    _clear_container()


func _use_selected_item() -> void:
    _count_popup.show_popup(_inventory.get_item(_selected_icon.index).count)
    var count: int = await _count_popup.count_selected

    # TODO: Add item using stuff

    var remainder := _inventory.adjust_count(_selected_icon.index, -1 * count)
    if not remainder:
        _selected_item_menu.clear()


func _drop_selected_item() -> void:
    _count_popup.show_popup(_inventory.get_item(_selected_icon.index).count)
    var count: int = await _count_popup.count_selected

    # TODO: Add item dropping stuff

    var remainder := _inventory.adjust_count(_selected_icon.index, -1 * count)
    if not remainder:
        _selected_item_menu.clear()


## TODO
func _update_inventory_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_toolbar_container.get_children() + _inventory_container.get_children())
    for i: int in range(_inventory.get_size()):
        var item := _inventory.get_item(i)
        if item.item_info and item.count > 0:
            icons[i].set_item(item.item_info, item.count)
        else:
            icons[i].clear_item()


## TODO
func _update_container_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_container_container.get_children())
    for i: int in range(_container.get_size()):
        var item := _container.get_item(i)
        if item.item_info and item.count > 0:
            icons[i].set_item(item.item_info, item.count)
        else:
            icons[i].clear_item()


func _start_move_mode() -> void:
    _move_mode = true
    _selected_icon.set_selection_mode(iInventoryIcon.SelectionMode.MOVE)
    # TODO: Show text that says "ESC to cancel" or something
    _selected_item_menu.set_buttons_disabled(true)


func _end_move_mode() -> void:
    _move_mode = false
    _selected_icon.set_selection_mode(iInventoryIcon.SelectionMode.DEFAULT)
    _selected_item_menu.set_buttons_disabled(false)

    if not _move_mode_icon:
        return

    var from_inventory := (
        _container if _selected_icon.get_parent() == _container_container else _inventory
    )

    if from_inventory.get_item(_selected_icon.index).count > 0:
        _move_mode_icon.deselect()
        _move_mode_icon = null
    else:
        _selected_icon.deselect()
        _selected_icon = _move_mode_icon
        _selected_item_menu.set_item(_selected_icon.get_item())


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _update_inventory_container()


## TODO
func set_container(container: Inventory) -> void:
    if _container:
        _container.updated.disconnect(_update_container_container)

    _container = container
    _container.updated.connect(_update_container_container)
    _container_panel.show()
    _update_container_container()


func _clear_container() -> void:
    _container = null
    _container_panel.hide()


func _on_icon_selection(icon: iInventoryIcon) -> void:
    if _move_mode:
        _move_item(icon)
    else:
        _set_selected_icon(icon)


func _set_selected_icon(icon: iInventoryIcon) -> void:
    if _selected_icon and _selected_icon != icon:
        _selected_icon.deselect()
    _selected_icon = icon
    _selected_item_menu.set_item(icon.get_item())


## TODO
func _move_item(icon: iInventoryIcon) -> void:
    _move_mode_icon = icon

    if _selected_icon == _move_mode_icon:
        return

    var target_item := _move_mode_icon.get_item()
    var source_item := _selected_icon.get_item()

    if target_item and target_item != source_item:
        _move_mode_icon.deselect()
        _move_mode_icon = null
        return

    var from_inventory := (
        _container if _selected_icon.get_parent() == _container_container else _inventory
    )
    var to_inventory := (
        _container if _move_mode_icon.get_parent() == _container_container else _inventory
    )

    var from_count := from_inventory.get_item(_selected_icon.index).count
    var to_count := to_inventory.get_item(_move_mode_icon.index).count
    var max_movable_count: int = min(Inventory.MAX_STACK_SIZE - to_count, from_count)
    if max_movable_count <= 0:
        _move_mode_icon.deselect()
        _move_mode_icon = null
        return

    _count_popup.show_popup(max_movable_count)
    var count: int = await _count_popup.count_selected

    if _move_mode_icon.get_item():
        to_inventory.adjust_count(_move_mode_icon.index, count)
    else:
        to_inventory.add_new_item(_move_mode_icon.index, source_item, count)

    var remainder := from_inventory.adjust_count(_selected_icon.index, -1 * count)
    if not remainder:
        _selected_icon.clear_item()
        _end_move_mode()
        return

    _move_mode_icon.deselect()
    _move_mode_icon = null
