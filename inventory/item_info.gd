@tool
class_name ItemInfo extends Resource
## Represents a usable item in the game. Contains all data for displaying this item and
## function to call on item use.

## The name of this item
@export var name: StringName
## Description to be shown in inventory
@export var description: String
## Icon for displaying in inventory
@export var icon: Texture2D
## Mesh for dispaying as a pickup
@export var mesh: Mesh
## Function in `ItemUser` to call when this item is used
@export var function: String
## Arguments for `function`
@export var args: Array[Variant]
