extends CanvasLayer

@export var show_fps: bool = true
@export var show_b: bool = true

@onready var fps_counter = $FPS_Counter
@onready var b_counter = $BCounter

var b_press_time_elapsed: float = 0

func _ready():
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

    if not show_fps:
        fps_counter.hide()
    if not show_b:
        b_counter.hide()

func _unhandled_input(event) -> void:
    if event is InputEventKey:
        if event.is_action_pressed('fullscreen'):
            DisplayServer.window_set_mode(
                DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
                else DisplayServer.WINDOW_MODE_FULLSCREEN
            )
        elif event.is_action_pressed('player_b'):
            b_press_time_elapsed = 0
    elif event is InputEventMouseButton and event.is_action_pressed('player_interact'):
            print('left click')

func _process(delta):
    if show_b:
        b_press_time_elapsed += delta
        b_counter.text = 'Seconds since the "B" key has been pressed: %d' % [int(b_press_time_elapsed)]

    if show_fps:
        fps_counter.text = str(Engine.get_frames_per_second())
