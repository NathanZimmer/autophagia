class_name MenuControl extends Control
## Base class for pause menus. Handles opening of sub-menus and closing of itself. [br]
## Place menu items for this menu at least within the first `VBoxContainer`. Place
## sub-menus as its siblings.

signal menu_exited

@export var _swap_map: Dictionary[Button, MenuControl]

var _child_menus: Array[MenuControl]

@onready var _back_button: Button = %BackButton
@onready var _menu_container: VBoxContainer = %VBoxContainer


func _ready() -> void:
    _back_button.pressed.connect(menu_exited.emit)
    _child_menus.assign(find_children("*", "MenuControl", false))
    for menu in _child_menus:
        menu.menu_exited.connect(_show_menu)
        menu.process_mode = ProcessMode.PROCESS_MODE_DISABLED
        menu.hide()

    for button: Button in _swap_map.keys():
        var menu := _swap_map[button]
        button.pressed.connect(_swap_to_submenu.bind(menu))


# Checking for this in _input because all buttons consume all mouse events when in focus.
# FIXME: Is this fine or should I implement the "proper" solution of updating the buttons?
func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.is_action_pressed(InputActions.UI.CANCEL):
        menu_exited.emit()
        accept_event()


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.CANCEL):
        menu_exited.emit()
        accept_event()


## Hide all child menus and show this menu
func _show_menu() -> void:
    for menu in _child_menus:
        menu.hide()
        menu.process_mode = ProcessMode.PROCESS_MODE_DISABLED
    _menu_container.show()


## Hide the contents of this menu and show the given submenu [br]
## ## Parameters [br]
## `submenu`: sub-menu to show [br]
## **Note**: `submenu` be a sibling of the first `VBoxContainer`
func _swap_to_submenu(submenu: Control) -> void:
    _menu_container.hide()
    submenu.show()
    submenu.process_mode = ProcessMode.PROCESS_MODE_INHERIT
