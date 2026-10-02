class_name PlayerProxyGizmo extends EditorNode3DGizmoPlugin

const COLOR = Color.DARK_MAGENTA
const ALPHA = 0.5

static var _material: StandardMaterial3D


func _init() -> void:
    # Creating materials manually instead of using create_material() because
    # it doesn't work  (#｀-_ゝ-)
    _material = StandardMaterial3D.new()
    _material.albedo_color = COLOR
    _material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _material.albedo_color.a = ALPHA
    _material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _create_gizmo(node: Node3D) -> EditorNode3DGizmo:
    if not (node is PlayerProxy):
        return null

    var gizmo = EditorNode3DGizmo.new()

    return gizmo


func _redraw(gizmo: EditorNode3DGizmo) -> void:
    gizmo.clear()
    _draw_gizmo(gizmo)


func _draw_gizmo(gizmo: EditorNode3DGizmo) -> void:
    var mesh = CapsuleMesh.new()
    mesh.height = 2
    mesh.radius = 0.5
    var transform = Transform3D.IDENTITY
    gizmo.add_mesh(mesh, _material, transform)
    gizmo.add_collision_triangles(mesh.generate_triangle_mesh())

    var line = CapsuleMesh.new()
    line.height = 1
    line.radius = 0.01
    var line_transform = Transform3D.IDENTITY
    line_transform.origin = Vector3(0, -0.5, -0.5)
    line_transform = line_transform.rotated(Vector3(1, 0, 0), PI * 0.5)
    gizmo.add_mesh(line, _material, line_transform)


func _get_gizmo_name() -> String:
    return "PlayerProxyGizmo"


func _has_gizmo(node: Node3D) -> bool:
    return node is PlayerProxy
