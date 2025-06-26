class_name SceneLoader extends Node2D


func _ready():
    ResourceLoader.load_threaded_request(Globals.scene_to_load_path, "", false)


func _process(_delta):
    if (
        ResourceLoader.load_threaded_get_status(Globals.scene_to_load_path)
        == ResourceLoader.THREAD_LOAD_LOADED
    ):
        var scene_to_load: PackedScene = ResourceLoader.load_threaded_get(
            Globals.scene_to_load_path
        )
        Globals.unpause.emit()
        get_tree().change_scene_to_packed(scene_to_load)
