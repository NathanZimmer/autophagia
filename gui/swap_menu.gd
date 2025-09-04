extends Button
## TODO

@export var _this_container: Container
@export var _target_menu: Control


func _ready() -> void:
    pressed.connect(_on_pressed)


func _on_pressed() -> void:
    _this_container.hide()
    _target_menu.show()
    _target_menu.process_mode = ProcessMode.PROCESS_MODE_INHERIT
