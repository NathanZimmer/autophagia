extends MeshInstance3D


func _ready() -> void:
    for child in get_children():
        child.triggered.connect(func(): print("Child triggered: %s" % child.name))
