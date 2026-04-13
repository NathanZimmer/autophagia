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

var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory
var _container: Inventory
var _selected_icon: iInventoryIcon

var _move_mode := false
var _move_from_icon: iInventoryIcon

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


func _on_exit() -> void:
    if _selected_icon:
        _selected_icon.deselct()
        _selected_icon = null
    _selected_item_menu.set_item(null)
    _clear_container()


func _use_selected_item() -> void:
    _count_popup.show_popup(_inventory.count_at_idx(_selected_icon.index))
    var count: int = await _count_popup.count_selected

    # TODO: Add item using stuff

    var depleted := _inventory.adjust_count(_selected_icon.index, -1 * count)
    if depleted:
        _selected_item_menu.set_item(null)


func _drop_selected_item() -> void:
    _count_popup.show_popup(_inventory.count_at_idx(_selected_icon.index))
    var count: int = await _count_popup.count_selected

    # TODO: Add item dropping stuff

    var depleted := _inventory.adjust_count(_selected_icon.index, -1 * count)
    if depleted:
        _selected_item_menu.set_item(null)


func _move_to_selected_item() -> void:
    if _selected_icon == _move_from_icon:
        return
    if _selected_icon._item and _selected_icon._item != _move_from_icon._item:
        _selected_icon.deselct()
        _selected_icon = null
        return

    var from_inventory := (
        _container if _move_from_icon.get_parent() == _container_container else _inventory
    )
    var to_inventory := (
        _container if _selected_icon.get_parent() == _container_container else _inventory
    )

    var from_count := from_inventory.count_at_idx(_move_from_icon.index)
    var to_count := to_inventory.count_at_idx(_selected_icon.index)
    var max_movable_count: int = min(Inventory.MAX_STACK_SIZE - to_count, from_count)
    if max_movable_count <= 0:
        _selected_icon.deselct()
        _selected_icon = null
        return

    _count_popup.show_popup(max_movable_count)
    var count: int = await _count_popup.count_selected

    if _selected_icon._item:
        to_inventory.adjust_count(_selected_icon.index, count)
    else:
        to_inventory._add_item_by_idx(_move_from_icon._item, _selected_icon.index, count)
    var depleted := from_inventory.adjust_count(_move_from_icon.index, -1 * count)
    if depleted:
        _move_from_icon.on_depletion()

    if from_count - count == 0:
        _end_move_mode()
    else:
        _selected_icon.deselct()
        _selected_icon = null


func _update_inventory_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_toolbar_container.get_children() + _inventory_container.get_children())
    for i: int in range(_inventory.get_size()):
        var item := _inventory.item_at_idx(i)
        var count := _inventory.count_at_idx(i)
        if item and count > 0:
            icons[i].set_item(item, count)
        else:
            icons[i].on_depletion()

    if _container:
        _update_container_container()


func _update_container_container() -> void:
    var container_icons: Array[iInventoryIcon]
    container_icons.assign(_container_container.get_children())
    for i: int in range(_container.get_size()):
        var item := _container.item_at_idx(i)
        var count := _container.count_at_idx(i)
        if item and count > 0:
            container_icons[i].set_item(item, count)


func _init_inventory_container() -> void:
    for child in _toolbar_container.get_children() + _inventory_container.get_children():
        child.queue_free()

    for i: int in range(0, TOOLBAR_SIZE):
        _add_icon_to(_toolbar_container, i)

    for i: int in range(TOOLBAR_SIZE, _inventory.get_size()):
        _add_icon_to(_inventory_container, i)

    _update_inventory_container()


func _add_icon_to(container: Container, inventory_idx: int) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    icon.index = inventory_idx
    icon.item_selected.connect(_updated_selected.bind(icon))
    container.add_child(icon)


func _start_move_mode() -> void:
    _move_mode = true
    _move_from_icon = _selected_icon
    _selected_icon = null
    _move_from_icon.set_selection_mode(iInventoryIcon.SelectionMode.MOVE_FROM)
    # TODO: Show text that says "ESC to cancel" or something
    _selected_item_menu.set_buttons_disabled(true)


func _end_move_mode() -> void:
    _move_mode = false
    _move_from_icon.set_selection_mode(iInventoryIcon.SelectionMode.DEFAULT)
    _selected_item_menu.set_buttons_disabled(false)

    if not _selected_icon:
        _selected_icon = _move_from_icon
        return

    var from_inventory := (
        _container if _move_from_icon.get_parent() == _container_container else _inventory
    )

    if from_inventory.count_at_idx(_move_from_icon.index) > 0:
        _selected_icon.deselct()
        _selected_icon = _move_from_icon
        _move_from_icon = null
        _selected_item_menu.set_item(_selected_icon._item)
    else:
        _move_from_icon.deselct()
        _move_from_icon = null


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _init_inventory_container()


## TODO
func set_container(container: Inventory) -> void:
    if _container:
        _container.updated.disconnect(_update_container_container)

    _container = container
    _container.updated.connect(_update_container_container)
    _container_panel.show()
    for i: int in range(container.get_size()):
        _add_icon_to(_container_container, i)
    _update_container_container()


func _clear_container() -> void:
    _container = null
    for child in _container_container.get_children():
        child.queue_free()
    _container_panel.hide()


func _updated_selected(item: ItemInfo, icon: iInventoryIcon) -> void:
    if _selected_icon and _selected_icon != icon:
        _selected_icon.deselct()
        if _move_mode:
            # FIXME: Why is this color only changing after being selected twice?
            _selected_icon.set_selection_mode(iInventoryIcon.SelectionMode.MOVE_TO)
    _selected_icon = icon

    if _move_mode:
        _move_to_selected_item()
    else:
        _selected_item_menu.set_item(item)
