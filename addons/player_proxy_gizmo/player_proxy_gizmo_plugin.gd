@tool
extends EditorPlugin

var _player_proxy_gizmo = PlayerProxyGizmo.new()


func _enter_tree():
    add_node_3d_gizmo_plugin(_player_proxy_gizmo)


func _exit_tree():
    remove_node_3d_gizmo_plugin(_player_proxy_gizmo)
