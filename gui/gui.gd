extends Control
## Handles menu and viewport related hotkeys, captures mouse, and connects to root pause menus

## Root pause menus
@onready var _pause_menu: MenuControl = %PauseMenu
@onready var _inventory_menu: MenuControl = %InventoryMenu


func _ready() -> void:
    _pause_menu.menu_exited.connect(_unpause)
    _inventory_menu.menu_exited.connect(_unpause)
    _unpause()


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.is_action_pressed(InputActions.UI.CANCEL):
            _pause(_pause_menu)
            accept_event()

        elif event.is_action_pressed(InputActions.UI.FULLSCREEN):
            _toggle_fullscreen()
            accept_event()

        elif event.is_action_pressed(InputActions.UI.INVENTORY):
            _pause(_inventory_menu)
            accept_event()


## Pause the game, show the mouse and pause menu
func _pause(menu: MenuControl) -> void:
    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    menu.show()


## Unpause the game, hide the mouse and pause menu
func _unpause() -> void:
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    _pause_menu.hide()
    _inventory_menu.hide()
    _pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
    _inventory_menu.process_mode = Node.PROCESS_MODE_DISABLED


## Toggle window mode between `WINDOW_MODE_FULLSCREEN` and `WINDOW_MODE_WINDOWED`
func _toggle_fullscreen() -> void:
    var fullscreen := Overrides.get_fullscreen()
    Overrides.set_fullscreen(!fullscreen)
