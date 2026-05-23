extends Node
## Constants for input map strings


## Constants for the player_* input actions
class Player:
    const LEFT := &"player_left"
    const RIGHT := &"player_right"
    const FORWARD := &"player_forward"
    const BACK := &"player_back"
    const UP := &"player_up"
    const DOWN := &"player_down"
    const INTERACT := &"player_interact"
    const USE_ITEM := &"player_use_item"
    const B := &"player_b"
    const FLIGHT_TOGGLE := &"player_flight_toggle"
    const COLLISION_TOGGLE := &"player_collision_toggle"


## Constants for the ui_* input actions
class Ui:
    const ACCEPT := &"ui_accept"
    const CANCEL := &"ui_cancel"
    const SELECT := &"ui_select"
    const BACK := &"ui_back"
    const UP := &"ui_up"
    const DOWN := &"ui_down"
    const LEFT := &"ui_left"
    const RIGHT := &"ui_right"
    const FULLSCREEN := &"ui_fullscreen"
    const INVENTORY := &"ui_inventory"
    const JOURNAL := &"ui_journal"
    const NEXT := &"ui_next"
    const PREV := &"ui_prev"
