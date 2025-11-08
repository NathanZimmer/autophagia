@tool
class_name Door extends AnimatableBody3D
## On `Lever.turned` emit, turns based on a curve
# FIXME: Make colliding with the door while it is opening/closing not janky

## Curve used for the open/close animation.
## Plays the animation in reverse for door closing. [br]
## * Domain: [0, x] where x is the duration of the animation in seconds [br]
## * Range: [0, y] where y is the maximum rotation angle in radians [br]
## The curve should start at y=0 to prevent jumps in rotation on animation start/end
@export var _curve: Curve = load("uid://kb8rx0mlxxwl")
## Axis to rotate around
@export var _rotation_axis: Vector3

@export_group("Audio")
## TODO
@export var _open_stream: AudioStream
## TODO
@export var _close_stream: AudioStream
## TODO
@export var _opening_stream: AudioStream
## TODO
@export var _volume_db: float

var _open := false
var _levers: Array[Lever]
var _tween: Tween
## Store tween interpolated value for changing door direction mid-animation
var _cur_sample_time: float
var _base_rotation: Quaternion
var _audio_player := AudioStreamPlayer3D.new()


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _curve.bake()
    _base_rotation = basis.get_rotation_quaternion()

    add_child(_audio_player)
    _audio_player.volume_db = _volume_db
    _audio_player.bus = &"Game"
    _audio_player.max_polyphony = 2

    _levers.assign(find_children("*", "Lever", false))
    for lever in _levers:
        lever.turned.connect(_open_close)
    _audio_player.position = _levers[0].position


## Tween over `_curve` forward or backward based on the state of `_open`.
## Can be interrupted and reversed by an additional call to `_open_close`
func _open_close() -> void:
    if _tween and _tween.is_running():
        _tween.stop()
        _open = !_open
    else:
        for lever in _levers:
            lever.disable_turning = true

    _tween = create_tween()
    _tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
    if _open:
        _tween.tween_method(_set_rotation_from_curve, _cur_sample_time, 0.0, _cur_sample_time)
    else:
        _tween.tween_method(
            _set_rotation_from_curve,
            _cur_sample_time,
            _curve.max_domain,
            _curve.max_domain - _cur_sample_time
        )
    _audio_player.stream = _opening_stream
    _audio_player.play(0.2)

    await _tween.finished

    _open = !_open
    if _open:
        _audio_player.stream = _open_stream
    else:
        _audio_player.stream = _close_stream
    _audio_player.play()

    for lever in _levers:
        lever.disable_turning = _open


## Sets rotation around `_rotation_axis` by sampling `_curve` at a given time [br]
## ## Parameters [br]
## `sample_time`: Time at which to sample the curve
func _set_rotation_from_curve(sample_time: float) -> void:
    _cur_sample_time = sample_time
    var angle := _curve.sample_baked(sample_time)
    basis = Basis(_base_rotation * Quaternion(_rotation_axis, angle))


## Show warning if we don't have a Lever child
func _get_configuration_warnings() -> PackedStringArray:
    var levers: Array = find_children("*", "Lever", false)

    var warnings: PackedStringArray = []
    if levers.is_empty():
        warnings.append("This node needs a Lever child to function.")

    return warnings
