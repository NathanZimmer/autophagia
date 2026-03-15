extends Control
## Handles menu and viewport related hotkeys, mouse capturing, crosshair,
## and connecting menus

## Raycast to use for setting crosshair icons
@export var _crosshair_raycast: RayCast3D
## Map of group name -> texture to display when `_crosshair_raycast` collides
## with that group
@export var _crosshair_textures: Dictionary[StringName, Texture2D]
@export var _message_handler: MessageHandler
@export var _journal: Journal

var _raycast_collided: Object
var _default_crosshair_texture: Texture2D

## Root pause menus
@onready var _pause_menu: iMenuControl = %PauseMenu
@onready var _journal_menu: iJournalMenuControl = %JournalMenu
@onready var _dialog_menu: iDialogMenuControl = %DialogMenu
@onready var _note_menu: iNoteMenuControl = %NoteMenu

@onready var _crosshair: TextureRect = %Crosshair


func _ready() -> void:
    _pause_menu.menu_exited.connect(_unpause.bind(_pause_menu))
    _unpause(_pause_menu)
    _journal_menu.menu_exited.connect(_unpause.bind(_journal_menu))
    _unpause(_journal_menu)
    _dialog_menu.menu_exited.connect(_unpause.bind(_dialog_menu))
    _unpause(_dialog_menu)
    _note_menu.menu_exited.connect(_unpause.bind(_note_menu))
    _unpause(_note_menu)

    _note_menu.inventory_button_pressed.connect(_swap_tojournal)
    _journal_menu.note_button_pressed.connect(_swap_to_note)

    if _message_handler:
        _message_handler.dialog_recieved.connect(_open_dialog_menu)
        _message_handler.note_received.connect(_open_note_menu)

    if _journal:
        _journal.note_discovered.connect(_journal_menu.add_note)

    _default_crosshair_texture = _crosshair.texture


func _physics_process(_delta: float) -> void:
    if _crosshair_raycast:
        _set_crosshair_texture()


func _shortcut_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.is_action_pressed(InputActions.UI.CANCEL):
            _pause(_pause_menu)
            accept_event()

        elif event.is_action_pressed(InputActions.UI.FULLSCREEN):
            _toggle_fullscreen()
            accept_event()

        elif event.is_action_pressed(InputActions.UI.INVENTORY):
            _pause(_journal_menu)
            accept_event()


## Pause the game, show the mouse and specified pause menu
func _pause(menu: iMenuControl) -> void:
    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    menu.show()
    _crosshair.hide()


func _open_dialog_menu(dialog: DialogTree) -> void:
    _dialog_menu.set_dialog(dialog)
    _pause(_dialog_menu)


# TODO: Make this bring up the page that the calling note is on
func _swap_tojournal() -> void:
    _note_menu.process_mode = Node.PROCESS_MODE_DISABLED
    _note_menu.hide()
    _pause(_journal_menu)


func _swap_to_note(title: Journal.Title) -> void:
    _journal_menu.process_mode = Node.PROCESS_MODE_DISABLED
    _journal_menu.hide()
    _open_note_menu(title)


func _open_note_menu(title: Journal.Title) -> void:
    var image: Texture2D = (
        _journal.get_note_texture(title) if _journal else PlaceholderTexture2D.new()
    )
    _note_menu.set_image(image)
    _note_menu.play_page_flip()
    _pause(_note_menu)


## Unpause the game, hide the mouse and pause menu
func _unpause(menu: iMenuControl) -> void:
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    menu.process_mode = Node.PROCESS_MODE_DISABLED
    menu.hide()
    _crosshair.show()


## Toggle window mode between `WINDOW_MODE_FULLSCREEN` and `WINDOW_MODE_WINDOWED`
func _toggle_fullscreen() -> void:
    var fullscreen := Overrides.load_fullscreen()
    Overrides.save_fullscreen(!fullscreen)


func _set_crosshair_texture() -> void:
    if not _crosshair.visible:
        return

    var collided := _crosshair_raycast.get_collider()
    if _raycast_collided == collided:
        return
    _raycast_collided = collided

    if not _raycast_collided:
        _crosshair.texture = _default_crosshair_texture
        return

    var overlap := _crosshair_textures.keys().filter(_raycast_collided.is_in_group)
    if not overlap:
        _crosshair.texture = _default_crosshair_texture
        return

    _crosshair.texture = _crosshair_textures[overlap[0]]
