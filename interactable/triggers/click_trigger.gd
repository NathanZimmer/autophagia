class_name ClickTrigger extends Area3D
## TODO

signal triggered

## Groups that can trigger this area
@export var _groups: Array[StringName]
## Input action to trigger this area
@export var _input_action: String


## TODO
func on_click(event: InputEvent, click_owner: Node3D) -> void:
    if event.is_action_pressed(_input_action):
        for group in _groups:
            if click_owner.is_in_group(group):
                triggered.emit(click_owner)
                return
