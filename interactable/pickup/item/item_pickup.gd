@tool
class_name ItemPickup extends Node3D
## On collision, sends an item to the colliding node. Colliding node should have a
## `MessageHandler` child. Queues iteslf for deletion if its count drops to zero.

## TODO
@export var _item_info: ItemInfo
## TODO
@export var _count := 1

var _item: InventoryItem
var _disable_next_collision := false

@onready var _floating_icon: MeshInstance3D = %FloatingIcon


func _ready() -> void:
    if _item_info and _item_info.mesh:
        _floating_icon.mesh = _item_info.mesh

    if Engine.is_editor_hint():
        return

    _item = InventoryItem.new(_item_info, _count)
    _item.depleted.connect(queue_free)

    var collision_triggers := find_children("*", "CollisionTrigger", false)
    for trigger in collision_triggers:
        trigger.triggered.connect(_send_item)


## TODO
func reset(item_info: ItemInfo, count: int) -> void:
    _disable_next_collision = true
    _item_info = item_info
    _count = count
    _floating_icon.mesh = _item_info.mesh
    _item.reset(_item_info, _count)


func _send_item(body: Node3D) -> void:
    if _disable_next_collision:
        _disable_next_collision = false
        return

    var handlers := body.find_children("*", "MessageHandler", false)
    if not handlers.is_empty():
        handlers[0].send_item(_item)


## Show warning if we don't have a CollisionTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var collision_triggers := find_children("*", "CollisionTrigger", false)

    var warnings: PackedStringArray = []
    if collision_triggers.is_empty():
        warnings.append("This node needs a CollisionTrigger child to function.")

    return warnings
