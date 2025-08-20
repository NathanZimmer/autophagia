extends MeshInstance3D


func _ready() -> void:
    for child in get_children():
        child.triggered.connect(
            func(body):
                print("Child triggered: %s, received body: %s" % [child.name, body])
        )
