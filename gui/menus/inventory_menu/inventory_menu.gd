class_name iInventoryMenu extends iMenuControl
## TODO
# TODO: Make the subviewport container work

# TODO:
    # - Make inventory size configurable
    # - Update highlighting to not rely on Control node focus
    # - Fix hard coding in inventory menu GUI
    # - Add support for moving items, using items, and dropping items
    # - Add support for moving items between inventory and containers


var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory

@onready var _inventory_container: GridContainer = %InventoryContainer

@onready var _name_label: Label = %NameLabel
@onready var _desc_label: Label = %DescLabel
@onready var _item_model: MeshInstance3D = %ItemModel

@onready var _use_button: Button = %UseButton
@onready var _move_button: Button = %MoveButton
@onready var _drop_button: Button = %DropButton


func _ready() -> void:
    super._ready()
    _select_item(null)


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if event is InputEventKey:
        if event.is_action_pressed(InputActions.UI.INVENTORY):
            menu_exited.emit()
            accept_event()
        elif event.is_action_pressed(InputActions.UI.JOURNAL):
            accept_event()


func _update_inventory_container() -> void:
    var icons: Array[iInventoryIcon]
    icons.assign(_inventory_container.get_children())

    for i: int in range(_inventory.get_size()):
        var item := _inventory.item_at_idx(i)
        var count := _inventory.count_at_idx(i)
        if item and count > 0:
            icons[i].set_item(item, count)


func _init_inventory_container() -> void:
    for child in _inventory_container.get_children():
        child.queue_free()
    for i: int in range(_inventory.get_size()):
        var icon: iInventoryIcon = InventoryIcon.instantiate()
        icon.item_selected.connect(_select_item)
        _inventory_container.add_child(icon)

    _update_inventory_container()


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _init_inventory_container()


## TODO
func _select_item(item: ItemInfo) -> void:
    if not item:
        _name_label.hide()
        _desc_label.hide()
        _item_model.hide()
        _use_button.hide()
        _move_button.hide()
        _drop_button.hide()
        return
    else:
        _name_label.show()
        _desc_label.show()
        _item_model.show()
        _use_button.show()
        _move_button.show()
        _drop_button.show()

    _name_label.text = item.name
    _desc_label.text = item.description
    _item_model.mesh = item.mesh
