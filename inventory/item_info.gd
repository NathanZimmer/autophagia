@tool
class_name ItemInfo extends Resource
## Represents a usable item in the game. Contains all data for displaying this item and
## function to call on item use.

@export_group("Visuals")
## The name of this item
@export var name: StringName
## Description to be shown in inventory
@export var description: String
## Icon for displaying in inventory
@export var icon: Texture2D
## Mesh for dispaying as a pickup
@export var mesh: Mesh
@export_group("Logic")
## Function in `ItemUser` to call when this item is used
@export var function: String
## Arguments for `function` [br]
## [b]Note:[/b] call to `function` will always have use count prepended to `args`
@export var args: Array[Variant]
## Whether you have to use this item one at a time
@export var can_use_multiple := true
## Whether using this item closes the inventory menu
@export var closes_menu := false


func _to_string() -> String:
    return "<name=%s, function=%s, args=%s>" % [name, function, args]
