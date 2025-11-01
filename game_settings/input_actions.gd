extends Node
## Constants for input map strings


class Player:
    ## Constants for the player_* input actions

    const LEFT: StringName = "player_left"
    const RIGHT: StringName = "player_right"
    const FORWARD: StringName = "player_forward"
    const BACK: StringName = "player_back"
    const UP: StringName = "player_up"
    const DOWN: StringName = "player_down"
    const INTERACT: StringName = "player_interact"
    const B: StringName = "player_b"
    const FLIGHT_TOGGLE: StringName = "player_flight_toggle"
    const COLLISION_TOGGLE: StringName = "player_collision_toggle"


class UI:
    ## Constants for the ui_* input actions

    const ACCEPT: StringName = "ui_accept"
    const CANCEL: StringName = "ui_cancel"
    const SELECT: StringName = "ui_select"
    const BACK: StringName = "ui_back"
    const UP: StringName = "ui_up"
    const DOWN: StringName = "ui_down"
    const LEFT: StringName = "ui_left"
    const RIGHT: StringName = "ui_right"
    const FULLSCREEN: StringName = "ui_fullscreen"
    const INVENTORY: StringName = "ui_inventory"
