class_name ClickTrigger extends Area3D
## A region of space that can be triggered by calling `on_click` with the correct input action. [br]
## Emits the `triggered` signal when these conditions are met.

signal triggered

## Groups that can trigger this area
@export var _groups: Array[StringName]
## Input action to trigger this area
@export_enum(PlayerInput.INTERACT_EXPORT_ENUM) var _input_action: String


## Emits `triggered(click_owner)` if event matches our input action [br]
## ## Parameters [br]
## `event`: input event to check against [br]
## `click_owner`: Node responsible for the click event [br]
func on_click(event: InputEvent, click_owner: Node3D) -> void:
    if event.is_action_pressed(_input_action) and _groups.any(click_owner.is_in_group):
        triggered.emit(click_owner)
