class_name GraphicsSettings extends Resource
## TODO

signal max_fps_updated
signal vsynch_updated
signal is_fullscreen_updated

@export var max_fps := 0:
    set(value):
        if value != max_fps:
            max_fps = value
            Engine.max_fps = value
            max_fps_updated.emit(value)
    get():
        return max_fps

@export var vsynch_mode := DisplayServer.VSYNC_DISABLED:
    set(value):
        if value != vsynch_mode:
            vsynch_mode = value
            DisplayServer.window_set_vsync_mode(vsynch_mode)
            vsynch_updated.emit(value)
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
            is_fullscreen_updated.emit(value)
    get():
        return is_fullscreen


func _init() -> void:
    Engine.max_fps = max_fps
    DisplayServer.window_set_vsync_mode(vsynch_mode)
    DisplayServer.window_set_mode(
        (
            DisplayServer.WINDOW_MODE_FULLSCREEN
            if is_fullscreen
            else DisplayServer.WINDOW_MODE_WINDOWED
        )
    )
