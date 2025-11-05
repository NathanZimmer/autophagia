@tool
class_name Lever extends MeshInstance3D
## On click, turns based on a curve and emits the `turned` signal

signal turned

## Curve used for the lever animation. [br]
## * Domain: [0, x] where x is the duration of the animation in seconds [br]
## * Range: [0, y] where y is the maximum rotation angle in radians [br]
## The curve should start and end at y=0 to prevent jumps in rotation on animation start/end
@export var _curve: Curve = load("uid://c7djvmapq1bjn")
## Axis to rotate around
@export var _rotation_axis: Vector3
## Index of the point on the curve to emit `turned` signal
@export var _emit_point: int

@export_group("Audio")
## TODO
@export var _open_stream: AudioStream
## TODO
@export var _close_stream: AudioStream
## TODO
@export var _volume_db: float

## Can disable animation and just emit the `turned` signal
var disable_turning := false

var _tween: Tween
var _base_rotation: Quaternion
var _timer: Timer
var _audio_player := AudioStreamPlayer3D.new()


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_rotation = basis.get_rotation_quaternion()

    add_child(_audio_player)
    _audio_player.volume_db = _volume_db
    _audio_player.bus = "Game"
    _audio_player.max_polyphony = 2

    _timer = Timer.new()
    add_child(_timer)
    _timer.wait_time = _curve.get_point_position(_emit_point).x
    _timer.one_shot = true
    _timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
    _timer.timeout.connect(turned.emit)

    var click_triggers: Array = find_children("*", "ClickTrigger", false)
    for click_trigger: ClickTrigger in click_triggers:
        click_trigger.triggered.connect(_turn)


## Tween over `_curve`. Emits the `turned` signal if `sample_time >= _emit_time`
func _turn(_body: Node3D) -> void:
    if _tween and _tween.is_running():
        return
    if disable_turning:
        turned.emit()
        _audio_player.stream = _open_stream
        _audio_player.play()
        return

    _tween = create_tween()
    _tween.tween_method(_set_rotation_from_curve, 0.0, _curve.max_domain, _curve.max_domain)
    _timer.start()

    _audio_player.stream = _open_stream
    _audio_player.play()
    _tween.finished.connect(
        func() -> void:
            _audio_player.stream = _close_stream
            _audio_player.play()
    )


## Sets rotation around `_rotation_axis` by sampling `_curve` at a given time [br]
## ## Parameters [br]
## `sample_time`: Time at which to sample the curve
func _set_rotation_from_curve(sample_time: float) -> void:
    var angle := _curve.sample_baked(sample_time)
    basis = Basis(_base_rotation * Quaternion(_rotation_axis, angle))


## Show warning if we don't have a ClickTrigger child
func _get_configuration_warnings() -> PackedStringArray:
    var click_triggers: Array = find_children("*", "ClickTrigger", false)

    var warnings: PackedStringArray = []
    if click_triggers.is_empty():
        warnings.append("This node needs a ClickTrigger child to function.")

    return warnings
