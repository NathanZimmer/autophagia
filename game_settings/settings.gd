extends Node
## TODO
# NOTE: Currently using path instead of UID because of a bug in Godot 4.4 that resets resource
# UIDs on project load

const PLAYER_SETTINGS_PATH = "res://game_settings/player_settings.tres"
const GRAPHICS_SETTINGS_PATH = "res://game_settings/graphics_settings.tres"

## runtime-configurable player settings
var player_settings: PlayerSettings = preload(PLAYER_SETTINGS_PATH)
## runtime-configurable graphics settings
var graphics_settings: GraphicsSettings = preload(GRAPHICS_SETTINGS_PATH)


func _ready() -> void:
    player_settings.load()
    graphics_settings.load()
