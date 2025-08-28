# extends Node
# ## Stores all global variables, signals, and hotkeys

# signal pause
# signal unpause
# signal close_menu
# signal change_mouse_sensitivity
# signal change_mouse_invertion
# signal change_resolution_scale
# signal toggle_fullscreen
# signal change_fov

# ## Path to the scene we want to load. Only used when a `SceneLoader` object is instantiated.
# var scene_to_load_path: String


# ## Sets certain values to their default
# func _ready() -> void:
#     process_mode = PROCESS_MODE_ALWAYS
#     DisplayServer.window_set_min_size(Vector2i(640, 360))
#     # Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#     # DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


# # Handle global hotkeys
# func _unhandled_input(event) -> void:
#     if event is InputEventKey:
#         if event.is_action_pressed("fullscreen"):
#             DisplayServer.window_set_mode(
#                 (
#                     DisplayServer.WINDOW_MODE_WINDOWED
#                     if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
#                     else DisplayServer.WINDOW_MODE_FULLSCREEN
#                 )
#             )
#             toggle_fullscreen.emit(
#                 DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
#             )
#             get_tree().get_root().set_input_as_handled()
