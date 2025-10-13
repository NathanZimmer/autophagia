class_name NoteMenuControl extends MenuControl

signal inventory_button_pressed

@onready var _note: TextureRect = %Note


func _ready() -> void:
    super._ready()

    var inventory_button: Button = get_node("%InventoryButton")
    inventory_button.pressed.connect(inventory_button_pressed.emit)


func set_image(image_texture: Texture2D) -> void:
    _note.texture = image_texture
