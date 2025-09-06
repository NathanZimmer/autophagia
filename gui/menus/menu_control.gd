class_name MenuController extends Control
## TODO
# TODO: Rename to MenuControl once gui_old is deleted

signal menu_exited

@export var _swap_map: Dictionary[Button, MenuController]

var _child_menus: Array[MenuController]

@onready var _back_button: Button = %BackButton
@onready var _menu_container: VBoxContainer = %VBoxContainer


func _ready() -> void:
    _back_button.pressed.connect(menu_exited.emit)
    _child_menus.assign(find_children("*", "MenuController", false))
    for menu in _child_menus:
        menu.menu_exited.connect(_show_menu)
        menu.process_mode = ProcessMode.PROCESS_MODE_DISABLED
        menu.hide()

    for button: Button in _swap_map.keys():
        var menu := _swap_map[button]
        button.pressed.connect(_swap_to_submenu.bind(menu))


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.is_action_pressed(InputActions.UI.CANCEL):
            menu_exited.emit()
            accept_event()


## Hide all child menus and show this menu
func _show_menu() -> void:
    for menu in _child_menus:
        menu.hide()
        menu.process_mode = ProcessMode.PROCESS_MODE_DISABLED
    _menu_container.show()


## TODO
func _swap_to_submenu(submenu: Control) -> void:
    _menu_container.hide()
    submenu.show()
    submenu.process_mode = ProcessMode.PROCESS_MODE_INHERIT
