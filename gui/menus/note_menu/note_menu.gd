class_name NoteMenuControl extends MenuControl
## Menu for displaying images

# TODO: Add support for multiple images when reading from inventory

signal inventory_button_pressed

@onready var _note: TextureRect = %Note
@onready var _page_flip: AudioStreamPlayer2D = %PageFlip


func _ready() -> void:
    super._ready()

    var inventory_button: Button = get_node("%InventoryButton")
    inventory_button.pressed.connect(inventory_button_pressed.emit)


func _shortcut_input(event: InputEvent) -> void:
    super._shortcut_input(event)
    if event is InputEventKey and event.is_action_pressed(InputActions.UI.INVENTORY):
        menu_exited.emit()
        accept_event()


func set_image(image_texture: Texture2D) -> void:
    _note.texture = image_texture


func play_page_flip() -> void:
    _page_flip.pitch_scale = 0.9 + randf_range(0.0, 0.2)
    _page_flip.play()
