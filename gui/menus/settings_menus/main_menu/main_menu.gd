extends MenuControl
## Handle input specific to main menu

# TODO: Add sub-menu for starting a new game or loading a save


func _ready() -> void:
    super._ready()
    _back_button.pressed.connect(func() -> void: get_tree().quit())
