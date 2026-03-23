class_name iInventoryMenu extends iMenuControl
## TODO
# TODO: Make the subviewport container work

var InventoryIcon := preload("uid://c4b0a3scm2jlc")
var _inventory: Inventory

@onready var _inventory_container: GridContainer = %InventoryContainer


func _ready() -> void:
    super._ready()


# FIXME: Make it so clicking buttons does not disable closing with tab
func _input(event: InputEvent) -> void:
    super._input(event)
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
        _inventory_container.add_child(icon)

    _update_inventory_container()


## TODO
func set_inventory(inventory: Inventory) -> void:
    if _inventory:
        _inventory.updated.disconnect(_update_inventory_container)

    _inventory = inventory
    _inventory.updated.connect(_update_inventory_container)
    _init_inventory_container()
