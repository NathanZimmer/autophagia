class_name iInventoryMenu extends iMenuControl
## TODO
# TODO: Make the subviewport container work

# TODO:
# - Add support for moving items, using items, and dropping items
# - Add support for moving items between inventory and containers

# TODO: Get rid of this when toolbar code is added
const TOOLBAR_SIZE := 4

var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory
var _container: Inventory
var _selected_icon: iInventoryIcon

@onready var _inventory_container: GridContainer = %InventoryContainer
@onready var _toolbar_container: GridContainer = %ToolbarContainer
@onready var _selected_item_menu: iSelectedItemMenu = %SelectedItemMenu

@onready var _container_panel: Panel = %ContainerPanel
@onready var _container_container: GridContainer = %ContainerContainer


func _ready() -> void:
    super._ready()
    menu_exited.connect(_on_exit)


func _shortcut_input(event: InputEvent) -> void:
    # super._shortcut_input(event)
    if event is InputEventKey:
        if (
            event.is_action_pressed(InputActions.UI.INVENTORY)
            or event.is_action_pressed(InputActions.UI.CANCEL)
        ):

            menu_exited.emit()
            accept_event()
        elif event.is_action_pressed(InputActions.UI.JOURNAL):
            accept_event()


func _on_exit() -> void:
    _selected_item_menu.set_item(null)
    _clear_container()


func _update_inventory_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_toolbar_container.get_children() + _inventory_container.get_children())
    for i: int in range(_inventory.get_size()):
        var item := _inventory.item_at_idx(i)
        var count := _inventory.count_at_idx(i)
        if item and count > 0:
            icons[i].set_item(item, count)

    if not _container:
        return

    var container_icons: Array[iInventoryIcon]
    container_icons.assign(_container_container.get_children())
    for i: int in range(_container.get_size()):
        var item := _container.item_at_idx(i)
        var count := _container.count_at_idx(i)
        if item and count > 0:
            icons[i].set_item(item, count)


func _init_inventory_container() -> void:
    for child in _toolbar_container.get_children() + _inventory_container.get_children():
        child.queue_free()

    for i: int in range(0, TOOLBAR_SIZE):
        _add_icon_to(_toolbar_container)

    for i: int in range(TOOLBAR_SIZE, _inventory.get_size()):
        _add_icon_to(_inventory_container)

    _update_inventory_container()


func _add_icon_to(container: Container) -> void:
    var icon: iInventoryIcon = InventoryIcon.instantiate()
    icon.item_selected.connect(_selected_item_menu.set_item)
    icon.item_selected.connect(_updated_selected_icon.bind(icon))
    container.add_child(icon)


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _init_inventory_container()


## TODO
func set_container(container: Inventory) -> void:
    _container = container
    _container_panel.show()
    for i: int in range(container.get_size()):
        _add_icon_to(_container_container)


func _clear_container() -> void:
    _container = null
    for child in _container_container.get_children():
        child.queue_free()
    _container_panel.hide()


func _updated_selected_icon(_0: Variant, icon: iInventoryIcon) -> void:
    if _selected_icon:
        _selected_icon.deselct()
    _selected_icon = icon
