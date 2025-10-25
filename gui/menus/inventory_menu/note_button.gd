@tool
extends Button
## TODO

# TODO: Add support for multiple image segment displays in button

@export var factor: float

# FIXME: Changing the size of text up increases the size of _label's box but changing
# it back down does not decrease the box size
@onready var _label: Label = %Label
@onready var _image_container: Container = %ImageContainer
@onready var _image: TextureRect = %Image

var _shader_material: ShaderMaterial


func _ready() -> void:
    if Engine.is_editor_hint():
        text = ""
        if _label:
            _label.resized.connect(
                func() -> void:
                    if _image_container:
                        _image_container.size.y = size.y - _label.size.y
                    _label.position.y = size.y - _label.size.y
            )

        resized.connect(
            func() -> void:
                if _image_container:
                    _image_container.size.x = size.x
                    _image_container.size.y = size.y - _label.size.y if _label else 0.0
                if _label:
                    _label.size.x = size.x
                    _label.position.y = size.y - _label.size.y
        )
        return

    # FIXME: This canvas_item shader is causing other UI elements to disappear as _image_container
    # is scrolled. Disabling for now and replacing with simple color modulation for hover
    var canvas_group: CanvasGroup = get_node("%CanvasGroup")
    canvas_group.material = null
    # _shader_material = canvas_group.material.duplicate()
    # canvas_group.material = _shader_material

    # mouse_entered.connect(func() -> void: _shader_material.set_shader_parameter("enabled", true))
    # mouse_exited.connect(func() -> void: _shader_material.set_shader_parameter("enabled", false))
    var hover_color := get_theme_color("font_hover_color", "Button") * factor
    mouse_entered.connect(func() -> void: canvas_group.modulate = hover_color)
    mouse_exited.connect(func() -> void: canvas_group.modulate = Color.WHITE)


func _get(property: StringName) -> Variant:
    if property == "text":
        return _label.text
    if property == "image":
        if _image:
            return _image.texture
        return PlaceholderTexture2D.new()

    return null


func _set(property: StringName, value: Variant) -> bool:
    if property == "text":
        if _label:
            _label.text = value
        return true
    if property == "image":
        if _image and _image.texture != value:
            _image.texture = value
        return true
    return false


func _get_property_list() -> Array:
    var property_list := []

    # Add the _image property to the editor
    property_list.append({
        "name": "image",
        "type": TYPE_OBJECT,
        "hint": PROPERTY_HINT_RESOURCE_TYPE,
        "hint_string": "Texture2D",
        "usage": PROPERTY_USAGE_DEFAULT
    })

    return property_list
