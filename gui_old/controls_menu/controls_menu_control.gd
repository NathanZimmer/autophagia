extends Control

@onready var sensitivity_slider_box_pair: Control = $SensitivitySliderBoxPair
@onready var invert_mouse_check_box: CheckBox = $InvertMouseCheckBox


func _ready() -> void:
    sensitivity_slider_box_pair.value_changed.connect(_change_sensitivity)
    invert_mouse_check_box.toggled.connect(_set_mouse_invertion)


func _change_sensitivity(value: int) -> void:
    Globals.change_mouse_sensitivity.emit(value)


func _set_mouse_invertion(inverted: bool) -> void:
    Globals.change_mouse_invertion.emit(inverted)
