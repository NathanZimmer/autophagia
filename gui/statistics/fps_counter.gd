extends Label
## Simple FPS counter for statistics


func _process(_delta: float) -> void:
    text = str(Engine.get_frames_per_second())
