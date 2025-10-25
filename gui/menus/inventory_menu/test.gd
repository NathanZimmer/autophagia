@tool
extends Control

func _ready() -> void:
	RenderingServer.canvas_item_set_canvas_group_mode(get_canvas_item(), RenderingServer.CANVAS_GROUP_MODE_CLIP_AND_DRAW, 10)