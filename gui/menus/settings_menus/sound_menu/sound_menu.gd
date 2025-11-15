extends MenuControl

@onready var _master_audio_slider := %MasterAudioSlider
@onready var _game_audio_slider := %GameAudioSlider
@onready var _menu_audio_slider := %MenuAudioSlider
@onready var _ambient_audio_slider := %AmbientAudioSlider


func _ready() -> void:
    super._ready()

    _connect_slider_to_bus(_master_audio_slider, &"Master")
    _connect_slider_to_bus(_game_audio_slider, &"Game")
    _connect_slider_to_bus(_menu_audio_slider, &"Menus")
    _connect_slider_to_bus(_ambient_audio_slider, &"Ambient")


func _connect_slider_to_bus(slider: Node, bus: StringName) -> void:
    slider.slider_drag_ended.connect(
        func(value_changed: bool) -> void:
            if not value_changed:
                return
            Overrides.save_audio(bus, int(slider.value))
    )
    slider.spin_box_value_changed.connect(
        func(new_value: float) -> void: Overrides.save_audio(bus, int(new_value))
    )
    slider.value = Overrides.load_audio(bus)
