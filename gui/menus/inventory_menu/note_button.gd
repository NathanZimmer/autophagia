extends VBoxContainer
## TODO

signal pressed

# TODO: Add support for multi-image buttons using pre-defined icons
# with small, medium, large, and full options

var _buttons: Array[TextureButton] = []

@onready var _note_container: Container = %NoteContainer

func _ready() -> void:
    for child: TextureButton in _note_container.get_children():
        _buttons.append(child)
        child.pressed.connect(pressed.emit)
        child.mouse_entered.connect(_set_color.bind(Color(1.0, 0.66, 0.66)))
        child.mouse_exited.connect(_set_color.bind(Color.WHITE))


func _set_color(color: Color) -> void:
    for button in _buttons:
        button.modulate = color

# func add_image(image: Texture2D) -> void:
#     var button := TextureButton.new()
#     button.texture = image
#     _note_container.add_child(button)
#     button.mouse_entered.connect(_set_color.bind(Color(1.0, 0.66, 0.66)))
#     button.mouse_exited.connect(_set_color.bind(Color.WHITE))


func set_label(text: String) -> void:
    var label: Label = get_node("%Label")
    label.text = text
