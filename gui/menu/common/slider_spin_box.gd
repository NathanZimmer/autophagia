extends BoxContainer
## Links values of `Slider` and `SpinBox`

## TODO
signal value_changed
## TODO
signal spin_box_value_changed
## TODO
signal slider_drag_ended

## TODO
var value: float:
    set(new_value):
        if value == new_value:
            return
        value = new_value
        _slider.value = value
        _spin_box.value = value
        value_changed.emit(value)

    get():
        return value

@onready var _slider: Slider = %Slider
@onready var _spin_box := %SpinBox


func _ready() -> void:
    _slider.value = value
    _spin_box.value = value

    _slider.value_changed.connect(func(new_value: float) -> void: value = new_value)
    _slider.drag_ended.connect(slider_drag_ended.emit)
    _spin_box.value_changed.connect(func(new_value: float) -> void: value = new_value)
    _spin_box.value_changed.connect(spin_box_value_changed.emit)
