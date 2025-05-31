class_name PortalBodyGizmo extends EditorNode3DGizmoPlugin

const COLOR_0 = Color.BLUE
const COLOR_1 = Color.ORANGE
const ALPHA = 0.3

static var _material_0: StandardMaterial3D
static var _material_1: StandardMaterial3D


func _init() -> void:
    # Creating materials manually instead of using create_material() because
    # it doesn't work  (#｀-_ゝ-)
    _material_0 = StandardMaterial3D.new()
    _material_0.albedo_color = COLOR_0
    _material_0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _material_0.albedo_color.a = ALPHA
    _material_0.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    _material_1 = StandardMaterial3D.new()
    _material_1.albedo_color = COLOR_1
    _material_1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    _material_1.albedo_color.a = ALPHA
    _material_1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _create_gizmo(node: Node3D) -> EditorNode3DGizmo:
    if not (node is PortalBody):
        return null

    var gizmo = EditorNode3DGizmo.new()

    return gizmo


func _redraw(gizmo: EditorNode3DGizmo) -> void:
    gizmo.clear()
    _draw_gizmo(gizmo)


func _draw_gizmo(gizmo: EditorNode3DGizmo) -> void:
    var size = gizmo.get_node_3d().size

    var mesh_0 = BoxMesh.new()
    mesh_0.size = Vector3(size.x, size.y, size.z / 2)
    var mesh_1 = BoxMesh.new()
    mesh_1.size = Vector3(size.x, size.y, size.z / 2)

    var transform_0 = Transform3D.IDENTITY
    transform_0.origin.z -= size.z / 4
    var transform_1 = Transform3D.IDENTITY
    transform_1.origin.z += size.z / 4

    gizmo.add_mesh(mesh_0, _material_0, transform_0)
    gizmo.add_mesh(mesh_1, _material_1, transform_1)
    gizmo.add_collision_triangles(mesh_0.generate_triangle_mesh())
    gizmo.add_collision_triangles(mesh_1.generate_triangle_mesh())


func _get_gizmo_name() -> String:
    return "PortalBodyGizmo"


func _has_gizmo(node: Node3D) -> bool:
    return node is PortalBody
