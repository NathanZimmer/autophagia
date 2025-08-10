class_name ClickTrigger extends Area3D
## A region of space that can be triggered by a specified input when a body
## of a specified group occupies it. [br]
## Emits the "triggered" signal when these conditions are met.

signal triggered

var _can_trigger := false

## Groups that can trigger this area
@export var _groups: Array[StringName]
## Input action to trigger this area
@export var _input_action: String

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)


func _physics_process(_delta) -> void:
    if _can_trigger and Input.is_action_just_pressed(_input_action):
        triggered.emit()


func _on_body_entered(body: Node) -> void:
    for group in body.get_groups():
        if group in _groups:
            _can_trigger = true


func _on_body_exited(body: Node) -> void:
    for group in body.get_groups():
        if group in _groups:
            _can_trigger = false
