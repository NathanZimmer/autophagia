@tool
extends EditorPlugin


var _portal_body_gizmo = PortalBodyGizmo.new()


func _enter_tree():
    add_node_3d_gizmo_plugin(_portal_body_gizmo)


func _exit_tree():
    remove_node_3d_gizmo_plugin(_portal_body_gizmo)
