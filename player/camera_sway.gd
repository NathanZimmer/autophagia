extends Node3D
## Handles camera sway on player movement
# TODO: Refactor, shorten code, make recentering smoother, make names better

## Curve used for TODO [br]
## TODO [br]
## The curve should start and end at the same y-value to prevent jumps in position on animation start/end
@export var _curve: Curve
## TODO
@export var _sway_duration: float
## TODO
@export var _starting_point: int

var _tween: Tween
var _return_tween: Tween
var _base_position: Vector3
var _reverse := false


func _ready() -> void:
    _curve.bake()
    _base_position = position


## Tween position over `_curve`
func _sway() -> void:
    if _tween and _tween.is_running():
        return

    if _return_tween and _return_tween.is_running():
        _return_tween.stop()

    _tween = create_tween()
    if _reverse:
        _tween.tween_method(
            _set_position_from_curve,
            position.x,
            _curve.min_domain,
            _sway_duration * _normalize_from_curve(position.x)
        )
    else:
        _tween.tween_method(
            _set_position_from_curve,
            position.x,
            _curve.max_domain,
            _sway_duration - _sway_duration * _normalize_from_curve(position.x)
        )
    _tween.finished.connect(_sway)
    _reverse = !_reverse


## TODO
func _set_position_from_curve(x_offset: float) -> void:
    var y_offset = _curve.sample_baked(x_offset)
    position = Vector3(
        _base_position.x + x_offset,
        _base_position.y + y_offset,
        _base_position.z
    )

## TODO
func start_sway() -> void:
    _sway()


## TODO
func _normalize_from_curve(x):
    return (x - _curve.min_domain) / (_curve.max_domain - _curve.min_domain)

## TODO
func stop_sway() -> void:
    if _return_tween and _return_tween.is_running():
        return

    if _tween and _tween.is_running():
        _tween.stop()

    var start_x := _curve.get_point_position(_starting_point).x
    _return_tween = create_tween()
    _return_tween.tween_method(
        _set_position_from_curve,
        position.x,
        start_x,
        _sway_duration * abs(
            _normalize_from_curve(start_x) -
            _normalize_from_curve(position.x)
        )
    )
    # _reverse = !_reverse
