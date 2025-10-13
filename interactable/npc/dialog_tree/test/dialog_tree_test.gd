extends Node2D


func _ready() -> void:
    var dialog_tree := DialogTree.new("res://interactable/npc/dialog_tree/dialog_tree_test.json")
    print(dialog_tree)
    await get_tree().create_timer(0.1).timeout
    get_tree().quit()
