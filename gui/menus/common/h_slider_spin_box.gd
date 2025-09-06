@tool
class_name HSliderSpinBox extends HSlider
## Links value of `HSlider` to a child `SpinBox`


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    var spin_box: SpinBox = find_children("*", "SpinBox", false)[0]
    value_changed.connect(_update_pair.bind(self, spin_box))
    spin_box.value_changed.connect(_update_pair.bind(spin_box, self))
    drag_ended.connect(_update_pair.bind(self, spin_box))
    spin_box.value_changed.connect(
        func(new_value: float) -> void: drag_ended.emit(new_value == value)
    )


## Update the paired controls when one changes
## TODO
func _update_pair(_value: Variant, source: Range, target: Range) -> void:
    if source.value == target.value:
        return
    target.value = source.value


## Show warning if we don't have a SpinBox child
func _get_configuration_warnings() -> PackedStringArray:
    var spin_boxes: Array = find_children("*", "SpinBox", false)

    var warnings: PackedStringArray = []
    if spin_boxes.is_empty():
        warnings.append("This node requires a SpinBox child.")

    return warnings
