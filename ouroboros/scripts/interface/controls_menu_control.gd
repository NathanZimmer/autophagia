extends Control


@onready var mouse_slider: Slider = $MouseSlider
@onready var mouse_spin_box: SpinBox = $MouseSpinBox
@onready var invert_mouse_check_box: CheckBox = $InvertMouseCheckBox

func _ready():
	mouse_slider.value_changed.connect(_slider_update)
	mouse_spin_box.value_changed.connect(_text_update)
	invert_mouse_check_box.toggled.connect(_set_mouse_invertion)
	Globals.mouse_sensitivity_changed.connect(_change_sensitivity)


func _process(_delta) -> void:
	pass


func _slider_update(value: float) -> void:
	Globals.mouse_sensitivity_changed.emit(int(value))


func _text_update(value: float) -> void:
	Globals.mouse_sensitivity_changed.emit(int(value))

func _set_mouse_invertion(inverted: bool) -> void:
	Globals._mouse_invertion_changed.emit(inverted)


func _change_sensitivity(sensitivity: int) -> void:
	mouse_slider.value = sensitivity
	mouse_spin_box.value = sensitivity
