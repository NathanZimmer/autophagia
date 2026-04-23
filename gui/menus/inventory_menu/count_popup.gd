class_name iCountPopup extends Control
## Popup menu that automatically hides itself when a count is selected

## Emit when a count is selected
signal count_selected(amount: int)

@onready var _select_spin_box: SpinBox = %SelectSpinBox
@onready var _submit_button: Button = %SubmitButton
@onready var _cancel_button: Button = %CancelButton


func _input(event: InputEvent) -> void:
    if not visible:
        return

    if event is InputEventKey or event is InputEventMouseButton:
        if (
            event.is_action_pressed(InputActions.Ui.INVENTORY)
            or event.is_action_pressed(InputActions.Ui.CANCEL)
        ):
            _on_cancel()
            accept_event()


func _ready() -> void:
    _submit_button.pressed.connect(_on_count_selected)
    _cancel_button.pressed.connect(_on_cancel)


## Show this popup and grab focus [br]
## ## Parameters [br]
## `max_count`: The max value of the popup SpinBox
func show_popup(max_count: int) -> void:
    show()
    _select_spin_box.grab_focus()
    _select_spin_box.max_value = max_count
    _select_spin_box.value = 1


func _on_count_selected() -> void:
    count_selected.emit(int(_select_spin_box.value))
    hide()


func _on_cancel() -> void:
    count_selected.emit(0)
    hide()
