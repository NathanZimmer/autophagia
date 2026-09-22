extends Node
## Manage interaction between player and nodes outside of its node hierarchy

var _player: iPlayer


func _ready() -> void:
    Utils.verify_component(self, _player, true)


## Assign the player node to interface with. Does not assign player if the value
## is already populated
func set_player(player: iPlayer) -> void:
    if not _player:
        _player = player
    else:
        push_error(
            (
                "set_player called but player is already assigned. "
                + "player: %s, provided player: %s" % [_player, player]
            )
        )


func get_camera_transform() -> Node3D:
    return _player.camera_remote_transform


func get_camera() -> Camera3D:
    return _player.camera


func get_player() -> Node3D:
    return _player
