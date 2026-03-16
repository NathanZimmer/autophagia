class_name iNoteMenuControl extends iMenuControl
## Menu for displaying images

# TODO: Add support for multiple images when reading from inventory

signal inventory_button_pressed

@onready var _note: TextureRect = %Note
@onready var _page_flip: AudioStreamPlayer2D = %PageFlip

## Whether this menu was navigated to from the journal menu
var opened_from_journal := false


func _ready() -> void:
    super._ready()

    var inventory_button: Button = get_node("%InventoryButton")
    inventory_button.pressed.connect(inventory_button_pressed.emit)

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.is_action_pressed(InputActions.UI.CANCEL):
        if opened_from_journal:
            inventory_button_pressed.emit()
        else:
            menu_exited.emit()
        accept_event()


func _shortcut_input(event: InputEvent) -> void:
    if (
        event is InputEventKey
        and (
            event.is_action_pressed(InputActions.UI.INVENTORY)
            or event.is_action_pressed(InputActions.UI.CANCEL)
        )
    ):
        if opened_from_journal:
            inventory_button_pressed.emit()
        else:
            menu_exited.emit()
        accept_event()


func set_image(image_texture: Texture2D) -> void:
    _note.texture = image_texture


func play_page_flip() -> void:
    _page_flip.pitch_scale = 0.9 + randf_range(0.0, 0.2)
    _page_flip.play()
