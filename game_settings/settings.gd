extends Node
## TODO
# NOTE: Currently using path instead of UID because of a bug in Godot 4.4 that resets resource
# UIDs on project load

## runtime-configurable player settings
var player_settings: PlayerSettings = preload("res://game_settings/player_settings.tres")
## runtime-configurable graphics settings
var graphics_settings: GraphicsSettings = preload("res://game_settings/graphics_settings.tres")
