class_name iGui extends Control
## Handles menu and viewport related hotkeys, mouse capturing, crosshair,
## and connecting menus

## Raycast to use for setting crosshair icons
@export_group("GUI")
## Map of group name -> texture to display when `_crosshair_raycast` collides
## with that group
@export var _crosshair_textures: Dictionary[StringName, Texture2D]
@export_group("Player Components")
## Player's journal component
@export var _journal: Journal
## Player's inventory component
@export var _inventory: Inventory
## Player's item user component
@export var _item_user: ItemUser

## Whether the player can open interaction menus. I.e, Dialog and Inventory
var _interact_menus_enabled := false

var _default_crosshair_texture: Texture2D
## Handle race condition between multiple menus attempting to open in the same frame
var _pause_lock: iMenuControl

## Root menus
@onready var _pause_menu: iMenuControl = %PauseMenu
@onready var _journal_menu: iJournalMenuControl = %JournalMenu
@onready var _dialog_menu: iDialogMenuControl = %DialogMenu
@onready var _note_menu: iNoteMenuControl = %NoteMenu
@onready var _inventory_menu: iInventoryMenu = %InventoryMenu
@onready var _toolbar: iToolbar = %Toolbar

@onready var _crosshair: TextureRect = %Crosshair


func _ready() -> void:
    _pause_menu.menu_exited.connect(_unpause.bind(_pause_menu))
    _journal_menu.menu_exited.connect(_unpause.bind(_journal_menu))
    _dialog_menu.menu_exited.connect(_unpause.bind(_dialog_menu))
    _note_menu.menu_exited.connect(_unpause.bind(_note_menu))
    _inventory_menu.menu_exited.connect(_unpause.bind(_inventory_menu))

    _note_menu.journal_button_pressed.connect(_pass_pause.bind(_note_menu, _journal_menu))
    _journal_menu.note_button_pressed.connect(open_note_menu.bind(true))

    if Utils.verify_component(self, _journal):
        _journal.note_discovered.connect(_journal_menu.add_note)

    if Utils.verify_component(self, _inventory):
        _inventory_menu.set_inventory(_inventory)
        _toolbar.set_inventory(_inventory)
    if Utils.verify_component(self, _item_user):
        _inventory_menu.set_item_user(_item_user)
        _toolbar.set_item_user(_item_user)
        _item_user.item_place_mode.connect(
            func(enabled: bool) -> void: _crosshair.visible = not enabled
        )

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    _default_crosshair_texture = _crosshair.texture


# func _physics_process(_delta: float) -> void:
    # if Utils.verify_component(self, _crosshair_raycast):
    #     _set_crosshair_texture()


func _shortcut_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return

    if event.is_action_pressed(InputActions.Ui.CANCEL):
        _pause(_pause_menu)
        accept_event()
    else:
        _handle_hotkeys(event)


func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        _handle_hotkeys(event)


func _handle_hotkeys(event: InputEvent) -> void:
    if event.is_action_pressed(InputActions.Ui.FULLSCREEN):
        Overrides.save_fullscreen(!Overrides.load_fullscreen())
        accept_event()
    elif event.is_action_pressed(InputActions.Ui.JOURNAL):
        _pause(_journal_menu)
        accept_event()

    elif _interact_menus_enabled and event.is_action_pressed(InputActions.Ui.INVENTORY):
        _pause(_inventory_menu)
        accept_event()


## Pause the game, show the mouse and given pause menu
func _pause(menu: iMenuControl) -> void:
    if _pause_lock:
        return
    _pause_lock = menu

    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    menu.show()
    _crosshair.hide()
    _toolbar.hide()


## Unpause the game, hide the mouse and pause menu
func _unpause(menu: iMenuControl) -> void:
    if _pause_lock == menu:
        _pause_lock = null
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        get_tree().paused = false
        _crosshair.show()
        _toolbar.show()
    else:
        push_error("Calling unpause on %s, but paused menu is %s" % [menu, _pause_lock])

    menu.process_mode = Node.PROCESS_MODE_DISABLED
    menu.hide()


## Pass pause and lock from one menu to another
func _pass_pause(from: iMenuControl, to: iMenuControl) -> void:
    if _pause_lock != from:
        push_error("Passing pause from %s, but paused menu is %s" % [from, _pause_lock])
        return
    _pause_lock = to

    from.process_mode = Node.PROCESS_MODE_DISABLED
    from.hide()
    to.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    to.show()


## Open the dialog menu with the given `DialogTree`
func open_dialog_menu(dialog: DialogTree) -> void:
    if not _interact_menus_enabled or _pause_lock:
        return
    _dialog_menu.set_dialog(dialog)
    _pause(_dialog_menu)


## Open the note menu to the given entry [br]
## ## Parameters [br]
## `title`: Title of entry to open [br]
## `from_journal`: If true, closing the menu will bring you back to `_journal_menu`
func open_note_menu(title: Journal.Title, from_journal: bool = false) -> void:
    if from_journal or not _pause_lock:
        var image: Texture2D = (
            _journal.get_note_texture(title) if _journal else PlaceholderTexture2D.new()
        )
        _note_menu.opened_from_journal = from_journal
        _note_menu.set_image(image)
        _note_menu.play_page_flip()

    if from_journal:
        _pass_pause(_journal_menu, _note_menu)
    else:
        _pause(_note_menu)


## Pass chest to and open `_inventory_menu`
func open_chest(chest: Inventory) -> void:
    if not _interact_menus_enabled or _pause_lock:
        return
    _inventory_menu.set_chest(chest)
    _pause(_inventory_menu)


## Set crosshair texture based on `_crosshair_textures`
func set_crosshair_texture(collided: Object) -> void:
    if not collided:
        _crosshair.texture = _default_crosshair_texture
        return

    var overlap := _crosshair_textures.keys().filter(collided.is_in_group)
    if not overlap:
        _crosshair.texture = _default_crosshair_texture
        return

    _crosshair.texture = _crosshair_textures[overlap[0]]


## Set whether the player can open the "interaction menus" (Dialog and Inventory)
func set_interact_menus_enabled(enabled: bool) -> void:
    _interact_menus_enabled = enabled
