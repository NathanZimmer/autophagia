extends Node
## User-configurable and saveable overrides for ProjectSettings. Handles saving and loading
##_to the `override.cfg` file and propagating changes throughout the engine.

signal vsynch_mode_changed
signal max_fps_changed
signal fullscreen_changed

signal mouse_sensitivity_changed
signal mouse_inverted_changed
signal field_of_view_changed

signal input_action_changed

const CONFIG_PATH = "override.cfg"
var config_file := ConfigFile.new()


func _ready() -> void:
    config_file.load(CONFIG_PATH)


func set_vsync_mode(mode: DisplayServer.VSyncMode) -> void:
    DisplayServer.window_set_vsync_mode(mode)
    config_file.set_value("display", "window/vsync/vsync_mode", mode)
    _save()
    vsynch_mode_changed.emit(mode)


func get_vsync_mode() -> DisplayServer.VSyncMode:
    var project_vsync: DisplayServer.VSyncMode = config_file.get_value(
        "display", "window/vsync/vsync_mode", DisplayServer.VSyncMode.VSYNC_ENABLED
    )
    var display_vsync := DisplayServer.window_get_vsync_mode()
    if project_vsync != display_vsync:
        push_warning(
            (
                "vsync mode is out of sync. ProjectSettings: %d, DisplayServer: %d"
                % [project_vsync, display_vsync]
            )
        )
    return display_vsync


func set_max_fps(max_fps: int) -> void:
    Engine.max_fps = max_fps
    config_file.set_value("application", "run/max_fps", max_fps)
    _save()
    max_fps_changed.emit(max_fps)


func get_max_fps() -> int:
    var project_fps: int = config_file.get_value("application", "run/max_fps", 0)
    var engine_fps := Engine.max_fps
    if engine_fps != project_fps:
        push_warning(
            "max fps is out of sync. ProjectSettings: %d, Engine: %d" % [project_fps, engine_fps]
        )
    return engine_fps


func set_fullscreen(fullscreen: bool) -> void:
    var window_mode := (
        DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN
        if fullscreen
        else DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
    )
    DisplayServer.window_set_mode(window_mode)
    config_file.set_value("display", "window/size/mode", window_mode)
    _save()
    fullscreen_changed.emit(fullscreen)


func get_fullscreen() -> bool:
    var project_fs: DisplayServer.WindowMode = config_file.get_value(
        "display", "window/size/mode", DisplayServer.WindowMode.WINDOW_MODE_WINDOWED
    )
    var display_fs := DisplayServer.window_get_mode()
    if project_fs != display_fs:
        push_warning(
            (
                "window mode is out of sync. ProjectSettings: %d, DisplayServer: %d"
                % [project_fs, display_fs]
            )
        )
    return project_fs == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN


func set_mouse_sensitivity(sensitivity: int) -> void:
    config_file.set_value("player", "camera/mouse_sensitivity", sensitivity)
    _save()
    mouse_sensitivity_changed.emit(sensitivity)


func get_mouse_sensitivity() -> int:
    return config_file.get_value("player", "camera/mouse_sensitivity", 50)


func set_mouse_inverted(inverted: bool) -> void:
    config_file.set_value("player", "camera/mouse_inverted", inverted)
    _save()
    mouse_inverted_changed.emit(inverted)


func get_mouse_inverted() -> bool:
    return config_file.get_value("player", "camera/mouse_inverted", false)


func set_fov(fov: int) -> void:
    config_file.set_value("player", "camera/field_of_view", fov)
    _save()
    field_of_view_changed.emit(fov)


func get_fov() -> int:
    return config_file.get_value("player", "camera/field_of_view", 90)


func set_input_action(action: String, event: InputEvent) -> void:
    InputMap.action_erase_events(action)
    InputMap.action_add_event(action, event)
    config_file.set_value("input", action, {"deadzone": 0.5, "events": [event]})
    _save()
    input_action_changed.emit(action, event)


func _save() -> int:
    return config_file.save(CONFIG_PATH)
