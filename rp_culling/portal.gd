@tool
class_name Portal extends Node3D
## TODO

## TODO
signal room_entered
## TODO
signal room_exited

## Room this portal connects to
@export var connected_room: Room
## Other portals visible through this portal in `connected_room`
@export var visible_portals: Array[Portal]
## Passing through the portal in this direction will trigger room entry, passing in the opposite
## direction will trigger room exit
@export var entry_direction := ThresholdTrigger.Direction.NEGATIVE_Z
## TODO
@export var _size: Vector3

@export_group("Trigger")
@export var _groups: Array[StringName]:
    get():
        return _groups

    set(value):
        if _groups == value:
            return
        _groups = value
        if _trigger:
            _trigger.groups = _groups

@export_flags_3d_physics var _collision_layer := 1:
    get():
        return _collision_layer

    set(value):
        if _collision_layer == value:
            return
        _collision_layer = value
        if _trigger:
            _trigger.collision_mask = _collision_layer

@export_flags_3d_physics var _collision_mask := 1:
    get():
        return _collision_mask

    set(value):
        if _collision_mask == value:
            return
        _collision_mask = value
        if _trigger:
            _trigger.collision_mask = _collision_mask

var _trigger: ThresholdTrigger


func _ready() -> void:
    if Engine.is_editor_hint():
        return
    _trigger = _create_threshold_trigger(_size)
    add_child(_trigger)
    _trigger.global_position = global_position
    _trigger.triggered.connect(_on_trigger)


func _on_trigger(_body: Node3D, direction: ThresholdTrigger.Direction) -> void:
    if direction == entry_direction:
        room_entered.emit()
    else:
        room_exited.emit()


## TODO
func show_connected_rooms() -> void:
    connected_room.show_room()
    for portal in visible_portals:
        portal.show_connected_rooms()


## TODO
func hide_connected_rooms() -> void:
    connected_room.hide_room()
    for portal in visible_portals:
        portal.hide_connected_rooms()


static func _create_threshold_trigger(size: Vector3) -> ThresholdTrigger:
    var shape := BoxShape3D.new()
    shape.size = size
    var collision_shape := CollisionShape3D.new()
    collision_shape.shape = shape
    var trigger := ThresholdTrigger.new()
    trigger.add_child(collision_shape)

    return trigger
