class_name Room extends Node3D
## TODO

## Number of layers deep the `show_room` call propogates down each `Portal`'s `visible_rooms`
const ROOM_VISIBILTY_DEPTH_LIMIT = 10

@export var _start_visible := false

var shown_this_frame := false

var _portals: Array[Portal]


func _ready() -> void:
    _portals.assign(find_children("*", "Portal", true))
    for portal in _portals:
        portal.room_entered.connect(show_rooms)
        portal.room_exited.connect(hide_rooms)

    if _start_visible:
        show_rooms()
    else:
        hide_rooms()


func _physics_process(_delta: float) -> void:
    shown_this_frame = false


## TODO
func show_rooms() -> void:
    show_room()
    for portal in _portals:
        portal.show_connected_rooms()


## TODO
func hide_rooms() -> void:
    hide_room()
    for portal in _portals:
        portal.hide_connected_rooms()


## TODO
func show_room() -> void:
    show()
    shown_this_frame = true


## TODO
func hide_room() -> void:
    if not shown_this_frame:
        hide()
