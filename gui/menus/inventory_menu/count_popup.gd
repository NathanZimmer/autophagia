class_name iCountPopup extends Control
## TODO

@onready var _select_spin_box: SpinBox = %SelectSpinBox
@onready var _submit_button: Button = %SubmitButton
@onready var _cancel_button: Button = %CancelButton

signal count_selected


func _shortcut_input(event: InputEvent) -> void:
    if not visible:
        return

    if event is InputEventKey:
        if (
            event.is_action_pressed(InputActions.UI.INVENTORY)
            or event.is_action_pressed(InputActions.UI.CANCEL)
        ):
            _on_cancel()
            accept_event()


func _ready() -> void:
    _submit_button.pressed.connect(_on_count_selected)
    _cancel_button.pressed.connect(_on_cancel)


## TODO
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
