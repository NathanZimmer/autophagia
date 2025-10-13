extends BoxContainer
## Links values of `Slider` and `SpinBox`

## Emitted when `value` changes
signal value_changed
## Emitted when the value of the spin box changes
signal spin_box_value_changed
## Emitted when the slider's grabber stops being dragged
signal slider_drag_ended

## Current value. Changing this property (even via code) will trigger value_changed
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
