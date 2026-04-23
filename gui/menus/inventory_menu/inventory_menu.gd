class_name iInventoryMenu extends iMenuControl
## Menu for interfacing with player `Inventory` component and container `Inventory`
## components

# TODO: Get rid of this when toolbar code is added
const TOOLBAR_SIZE := 4

const MAX_CONTAINER_SIZE := 5
const MAX_INVENTORY_SIZE := 12

var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory
var _container: Inventory
var _item_user: ItemUser

## Map icons in GUI to corresponding indices in Inventory
var _icon_index_map: Dictionary[iInventoryIcon, int]

var _selected_icon: iInventoryIcon

var _move_mode := false
var _move_mode_icon: iInventoryIcon

@onready var _inventory_container: GridContainer = %InventoryContainer
@onready var _toolbar_container: GridContainer = %ToolbarContainer
@onready var _selected_item_menu: iSelectedItemMenu = %SelectedItemMenu
@onready var _count_popup: iCountPopup = %CountPopup

@onready var _move_mode_button: Button = %CancelMoveModeButton

@onready var _container_panel: Panel = %ContainerPanel
@onready var _container_container: GridContainer = %ContainerContainer


func _ready() -> void:
    super._ready()
    menu_exited.connect(_on_exit)

    _selected_item_menu.use_button_pressed.connect(_use_selected_item)
    _selected_item_menu.drop_button_pressed.connect(_drop_selected_item)
    _selected_item_menu.move_button_pressed.connect(_start_move_mode)
    _move_mode_button.pressed.connect(_end_move_mode)

    _init_inventory_container()
    _init_container_container()


func _input(event: InputEvent) -> void:
    if event is InputEventKey or event is InputEventMouseButton:
        if (
            event.is_action_pressed(InputActions.Ui.INVENTORY)
            or event.is_action_pressed(InputActions.Ui.CANCEL)
        ):
            if _move_mode:
                _end_move_mode()
            else:
                menu_exited.emit()
            accept_event()


func _shortcut_input(event: InputEvent) -> void:
    # super._shortcut_input(event)
    if event is InputEventKey and event.is_action_pressed(InputActions.Ui.JOURNAL):
        accept_event()


## Perform cleanup and reset for closing menu
func _on_exit() -> void:
    if _selected_icon:
        _selected_icon.deselect()
        _selected_icon = null
    _selected_item_menu.clear()
    _clear_container()


## Add `InventoryIcon` children to inventory container
func _init_inventory_container() -> void:
    for i: int in range(0, TOOLBAR_SIZE):
        _add_icon(_toolbar_container, i)
    for i: int in range(TOOLBAR_SIZE, MAX_INVENTORY_SIZE):
        _add_icon(_inventory_container, i)


## Add `InventoryIcon` children to the "container" container
func _init_container_container() -> void:
    for i: int in range(0, MAX_CONTAINER_SIZE):
        _add_icon(_container_container, i)


## Adds an icon to the specified container [br]
## ## Parameters [br]
## `container`: Node to add `InventoryIcon` child to [br]
## `container_idx`: Index in this container to add to. This is added to `_icon_index_map`
## for later use
func _add_icon(container: Container, container_index: int) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    _icon_index_map[icon] = container_index
    icon.item_selected.connect(_on_icon_selection)
    container.add_child(icon)


func _use_selected_item() -> void:
    var idx := _icon_index_map[_selected_icon]
    var item := _inventory.get_item(idx)

    _count_popup.show_popup(item.count if item.item_info.can_use_multiple else 1)
    var count: int = await _count_popup.count_selected

    var used := _item_user.use_item(item.item_info, item.count)
    if not used:
        return

    var remainder := _inventory.remove_count(idx, count)
    if not remainder:
        _selected_item_menu.clear()


func _drop_selected_item() -> void:
    var idx := _icon_index_map[_selected_icon]
    var item := _inventory.get_item(idx)

    _count_popup.show_popup(item.count)
    var count: int = await _count_popup.count_selected

    _item_user.drop_item(item.item_info, count)
    var remainder := _inventory.remove_count(idx, count)
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


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _update_inventory_container()


func set_item_user(item_user: ItemUser) -> void:
    _item_user = item_user


## TODO
func set_container(container: Inventory) -> void:
    if _container:
        _container.updated.disconnect(_update_container_container)

    _container = container
    _container.updated.connect(_update_container_container)
    _container_panel.show()
    _update_container_container()


func _clear_container() -> void:
    if _container:
        _container.updated.disconnect(_update_container_container)
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
    _selected_item_menu.set_buttons_disabled(_container != null, false, _container != null)


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
    var from_idx := _icon_index_map[_selected_icon]
    var to_inventory := (
        _container if _move_mode_icon.get_parent() == _container_container else _inventory
    )
    var to_idx := _icon_index_map[_move_mode_icon]

    var from_count := from_inventory.get_item(from_idx).count
    var to_count := to_inventory.get_item(to_idx).count
    var max_movable_count: int = min(Inventory.MAX_STACK_SIZE - to_count, from_count)
    if max_movable_count <= 0:
        _move_mode_icon.deselect()
        _move_mode_icon = null
        return

    _count_popup.show_popup(max_movable_count)
    var count: int = await _count_popup.count_selected
    if count == 0:
        _move_mode_icon.deselect()
        _move_mode_icon = null
        return

    if _move_mode_icon.get_item():
        to_inventory.add_count(to_idx, count)
    else:
        to_inventory.add_new_item(to_idx, source_item, count)

    var remainder := from_inventory.remove_count(from_idx, count)
    if not remainder:
        _selected_icon.clear_item()

    _end_move_mode()


func _start_move_mode() -> void:
    _move_mode = true
    _selected_icon.set_selection_mode(iInventoryIcon.SelectionMode.MOVE)
    _selected_item_menu.set_buttons_disabled(true, true, true)
    _move_mode_button.show()


func _end_move_mode() -> void:
    _move_mode = false
    _selected_icon.set_selection_mode(iInventoryIcon.SelectionMode.DEFAULT)
    _selected_item_menu.set_buttons_disabled(_container != null, false, _container != null)
    _move_mode_button.hide()

    if not _move_mode_icon:
        return

    _selected_icon.deselect()
    _selected_icon = _move_mode_icon
    _selected_item_menu.set_item(_selected_icon.get_item())
