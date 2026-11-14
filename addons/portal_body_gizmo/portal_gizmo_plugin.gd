@tool
extends EditorPlugin

var _portal_gizmo = PortalGizmo.new()


func _enter_tree():
    add_node_3d_gizmo_plugin(_portal_gizmo)


func _exit_tree():
    remove_node_3d_gizmo_plugin(_portal_gizmo)
