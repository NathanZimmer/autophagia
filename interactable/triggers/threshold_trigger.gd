class_name ThresholdTrigger extends Area3D
## Emits `triggered(body)` whenever a body crosses the x-axis of the trigger

signal triggered(body: Node3D, direction: Direction)

enum Direction { POSITIVE_Z = 1, NEGATIVE_Z = -1 }

## Groups to be tracked by this trigger
@export var groups: Array[StringName]

var _body_directions: Dictionary[Node3D, int]


func _ready() -> void:
    body_entered.connect(_on_body_enter)
    body_exited.connect(_on_body_enter)


func _on_body_enter(body: Node3D) -> void:
    if groups.any(body.is_in_group):
        return

    var co_pointing := int(sign(global_basis.z.dot(body.global_position - global_position)))
    if co_pointing != 0:
        _body_directions[body] = co_pointing


func _process(_delta: float) -> void:
    for body in _body_directions:
        var co_pointing := int(sign(global_basis.z.dot(body.global_position - global_position)))
        if co_pointing in [0, _body_directions[body]]:
            continue

        _body_directions[body] = co_pointing
        triggered.emit(body, co_pointing)


func _on_body_exit(body: Node3D) -> void:
    _body_directions.erase(body)
