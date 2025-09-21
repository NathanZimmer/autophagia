class_name GraphicsSettings extends Resource
## Holds runtime-configurable graphics settings. Updates relevant Autoload globals and
## emits *_changed signal when variables are updated

signal max_fps_changed
signal vsynch_changed
signal is_fullscreen_changed

@export var max_fps := 0:
    set(value):
        if value != max_fps:
            max_fps = value
            Engine.max_fps = value
            max_fps_changed.emit(value)
    get():
        return max_fps

@export var vsynch_mode := DisplayServer.VSYNC_ENABLED:
    set(value):
        if value != vsynch_mode:
            vsynch_mode = value
            DisplayServer.window_set_vsync_mode(vsynch_mode)
            vsynch_changed.emit(value)
    get():
        return vsynch_mode

@export var is_fullscreen := false:
    set(value):
        if value != is_fullscreen:
            is_fullscreen = value
            DisplayServer.window_set_mode(
                (
                    DisplayServer.WINDOW_MODE_FULLSCREEN
                    if is_fullscreen
                    else DisplayServer.WINDOW_MODE_WINDOWED
                )
            )
            is_fullscreen_changed.emit(value)
    get():
        return is_fullscreen


## Override Autoload globals
func load() -> void:
    Engine.max_fps = max_fps
    DisplayServer.window_set_vsync_mode(vsynch_mode)
    DisplayServer.window_set_mode(
        (
            DisplayServer.WINDOW_MODE_FULLSCREEN
            if is_fullscreen
            else DisplayServer.WINDOW_MODE_WINDOWED
        )
    )
