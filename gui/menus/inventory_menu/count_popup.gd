class_name iCountPopup extends Control
## Popup menu that automatically hides itself when a count is selected

## Emit when a count is selected
signal count_selected(amount: int)
@onready var _count_label: Label = %CountLabel
@onready var _confirm_label: Label = %ConfirmLabel
@onready var _select_spin_box: SpinBox = %SelectSpinBox
@onready var _submit_button: Button = %SubmitButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
    _submit_button.pressed.connect(_on_count_selected)
    _cancel_button.pressed.connect(_on_cancel)
    # Enable wrapping
    _select_spin_box.value_changed.connect(
        func(value: float) -> void:
            if int(value) == _select_spin_box.min_value - 1:
                _select_spin_box.value = _select_spin_box.max_value
            elif int(value) == _select_spin_box.max_value + 1:
                _select_spin_box.value = _select_spin_box.min_value
    )


func _shortcut_input(event: InputEvent) -> void:
    if not (event is InputEventKey or event is InputEventMouseButton):
        return

    if event.is_action_pressed(InputActions.Ui.CANCEL):
        _on_cancel()
        accept_event()
    elif event.is_action_pressed(InputActions.Ui.INVENTORY):
        accept_event()


## Show this popup and enable processing[br]
## ## Parameters [br]
## `max_count`: The max value of the popup SpinBox [br]
## `show_spin_box`: Whether to hide the spin box and show alternate single-item popup
func show_popup(max_count: int, show_spin_box: bool = true) -> void:
    show()
    process_mode = Node.PROCESS_MODE_INHERIT
    _select_spin_box.max_value = max_count
    _select_spin_box.value = 1

    _count_label.visible = show_spin_box
    _select_spin_box.visible = show_spin_box
    _confirm_label.visible = not show_spin_box


func _on_count_selected() -> void:
    count_selected.emit(int(_select_spin_box.value))
    hide()


## Hide this popup and disable processing
func _on_cancel() -> void:
    count_selected.emit(0)
    hide()
    process_mode = Node.PROCESS_MODE_DISABLED
