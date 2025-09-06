extends Control
## Connects the values of a `Slider` and `SpinBox`

signal value_changed

@export var limit_to_int := true

var value: float = 0:
    set(new_value):
        if value == new_value:
            return

        value = new_value
        if limit_to_int:
            slider.value = int(value)
            spin_box.value = int(value)
        else:
            slider.value = value
            spin_box.value = value

    get:
        if limit_to_int:
            return int(value)
        return value

@onready var slider: Slider = $Slider
@onready var spin_box: SpinBox = $SpinBox


func _ready() -> void:
    slider.value_changed.connect(_value_changed)
    slider.drag_ended.connect(_drag_ended)
    spin_box.value_changed.connect(_value_changed)


func _value_changed(new_value: float) -> void:
    if new_value == value:
        return

    if limit_to_int:
        slider.value = int(new_value)
        spin_box.value = int(new_value)
    else:
        slider.value = new_value
        spin_box.value = new_value

    value = new_value


func _drag_ended(changed: bool) -> void:
    if not changed:
        return

    if limit_to_int:
        value_changed.emit(int(slider.value))
    else:
        value_changed.emit(slider.value)
