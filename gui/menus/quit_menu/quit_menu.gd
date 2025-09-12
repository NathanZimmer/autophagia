extends MenuController


@onready var _quit_main_button: Button = %QuitMainButton
@onready var _quit_desktop_button: Button = %QuitDesktopButton

func _ready() -> void:
    super._ready()

    _quit_main_button.pressed.connect(func()-> void: print("TODO"))
    _quit_desktop_button.pressed.connect(get_tree().quit)
