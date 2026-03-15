extends Node2D

@onready var _inventory: Inventory = %Inventory

var item_0: InventoryItem = load("uid://bjit7wcgwvpet")
var item_1: InventoryItem = load("uid://bw72jyk5h40q5")


func _ready() -> void:
    _inventory.add_item_by_idx(item_0, 5, 1)
    _inventory.add_item(item_0, 13)
    _inventory.add_item_by_idx(item_1, 4, 1)
    _inventory.add_item(item_1, 13)
    _print_inventory()
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()


func _print_inventory() -> void:
    for i in range(len(_inventory._items)):
        print("(%s, %d)" % [_inventory._items[i], _inventory._count[i]])
