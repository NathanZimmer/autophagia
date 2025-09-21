class_name PlayerSettings extends Resource
## Holds runtime-configurable player settings. Updates relevant Autoload globals and
## emits *_changed signal when variables are updated
# NOTE: Expects the constants from input_actions.gd to be defined in the engine

signal mouse_sensitivity_changed
signal mouse_inverted_changed
signal fov_changed
signal forward_changed
signal backward_changed
signal left_changed
signal right_changed
signal jump_changed
signal interact_changed
signal fullscreen_changed

@export_group("Camera")
@export_range(1, 100, 1) var mouse_sensitivity := 50:
    set(value):
        if value != mouse_sensitivity:
            mouse_sensitivity = value
            mouse_sensitivity_changed.emit(value)
    get():
        return mouse_sensitivity

@export var mouse_inverted := false:
    set(value):
        if value != mouse_inverted:
            mouse_inverted = value
            mouse_inverted_changed.emit(value)
    get():
        return mouse_inverted

@export_range(50, 110) var fov := 90:
    set(value):
        if value != fov:
            fov = value
            fov_changed.emit(value)
    get():
        return fov

@export_group("Input Map")
@export var forward: InputEvent:
    set(value):
        if value != forward:
            forward = value
            InputMap.action_erase_events(InputActions.Player.FORWARD)
            InputMap.action_add_event(InputActions.Player.FORWARD, forward)
            forward_changed.emit(value)
    get():
        return forward

@export var backward: InputEvent:
    set(value):
        if value != backward:
            backward = value
            InputMap.action_erase_events(InputActions.Player.BACK)
            InputMap.action_add_event(InputActions.Player.BACK, backward)
            backward_changed.emit(value)
    get():
        return backward

@export var left: InputEvent:
    set(value):
        if value != left:
            left = value
            InputMap.action_erase_events(InputActions.Player.LEFT)
            InputMap.action_add_event(InputActions.Player.LEFT, left)
            left_changed.emit(value)
    get():
        return left

@export var right: InputEvent:
    set(value):
        if value != right:
            right = value
            InputMap.action_erase_events(InputActions.Player.RIGHT)
            InputMap.action_add_event(InputActions.Player.RIGHT, right)
            right_changed.emit(value)
    get():
        return right

@export var jump: InputEvent:
    set(value):
        if value != jump:
            jump = value
            InputMap.action_erase_events(InputActions.Player.UP)
            InputMap.action_add_event(InputActions.Player.UP, jump)
            jump_changed.emit(value)
    get():
        return jump

@export var interact: InputEvent:
    set(value):
        if value != interact:
            interact = value
            InputMap.action_erase_events(InputActions.Player.INTERACT)
            InputMap.action_add_event(InputActions.Player.INTERACT, interact)
            interact_changed.emit(value)
    get():
        return interact

@export var fullscreen: InputEvent:
    set(value):
        if value != fullscreen:
            fullscreen = value
            InputMap.action_erase_events(InputActions.UI.FULLSCREEN)
            InputMap.action_add_event(InputActions.UI.FULLSCREEN, fullscreen)
            fullscreen_changed.emit(value)
    get():
        return fullscreen

# This is what I have to do as a stand-in for reference vars (┬┬﹏┬┬)
var _input_map: Dictionary[String, String] = {
    InputActions.Player.FORWARD: "forward",
    InputActions.Player.BACK: "backward",
    InputActions.Player.LEFT: "left",
    InputActions.Player.RIGHT: "right",
    InputActions.Player.UP: "jump",
    InputActions.Player.INTERACT: "interact",
    InputActions.UI.FULLSCREEN: "fullscreen"
}


## Override Autoload globals
func load() -> void:
    for action: String in _input_map.keys():
        var event: InputEvent = get(_input_map[action])
        InputMap.action_erase_events(action)
        InputMap.action_add_event(action, event)


## TODO
func set_input(event: InputEvent, action: String) -> void:
    set(_input_map[action], event)
