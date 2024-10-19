class_name PauseControl extends Control
## Class for swapping pause sub-menus and unpausing the game

## Stores the order we visit menus in so we can properly handle navigating out.
var menu_stack: Array[Control] = []
var visible_menu: Control


func _ready():
	Globals.pause.connect(pause)
	visible_menu = get_child(0)
	unpause()


func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			close_menu()
			get_tree().get_root().set_input_as_handled()


## Store currently open menu, hide it, and open `to_show`
func open_menu(to_show: Control):
	visible_menu.hide()
	menu_stack.push_front(visible_menu)

	visible_menu = to_show
	visible_menu.show()


## Close currently open menu, show previous menu
func close_menu():
	if len(menu_stack) == 0:
		unpause()
		return

	visible_menu.hide()
	visible_menu = menu_stack.pop_front()

	visible_menu.show()


## Starts a pause state: shows base menu and frees mouse
func pause():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()


## Terminates the pause state: emits a global unpause and captures mouse
func unpause():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
	get_tree().paused = false