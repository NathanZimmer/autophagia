extends EditorScenePostImport
## Script to recursively add occluders to MeshInstance3D nodes with the "-occ" tag.
## Only works for nodes with mesh of type ArrayMesh, QuadMesh, BoxMesh, or SphereMesh


const OCCLUDER_TAG = "-occ"
const OCCLUDER_ONLY_TAG = "-occonly"


func _post_import(scene: Node) -> Object:
    # if is_instance_of(scene, Node3D):
    #     _recursive_add_occluders(scene)
    return scene


func _recursive_add_occluders(node: Node3D) -> void:
    if node == null:
        return

    var ends_with_tag := node.name.ends_with(OCCLUDER_TAG) or node.name.ends_with(OCCLUDER_ONLY_TAG)
    if is_instance_of(node, MeshInstance3D) and ends_with_tag:
        var occluder := _mesh_to_occluder(node.mesh, node.name)
        if occluder:
            var occluder_instance := OccluderInstance3D.new()
            occluder_instance.occluder = occluder
            if node.name.ends_with(OCCLUDER_TAG):
                node.name = node.name.substr(0, node.name.length() - OCCLUDER_TAG.length())
                node.add_child(occluder_instance, true)
                occluder_instance.owner = node.owner
            else:
                var name := node.name.substr(0, node.name.length() - OCCLUDER_ONLY_TAG.length())
                occluder_instance.name = name
                occluder_instance.owner = node.owner
                occluder_instance.transform = node.transform
                node.replace_by(occluder_instance, true)
                node.free()

    for child in node.get_children():
        _recursive_add_occluders(child)


func _mesh_to_occluder(mesh: Mesh, name: StringName) -> Occluder3D:
    var occluder: Occluder3D
    if mesh is ArrayMesh:
        occluder = ArrayOccluder3D.new()
        var vertices: PackedVector3Array
        var indices: PackedInt32Array
        for i in range(mesh.get_surface_count()):
            var arrays := mesh.surface_get_arrays(i)
            vertices.append_array(arrays[Mesh.ARRAY_VERTEX])
            indices.append_array(arrays[Mesh.ARRAY_INDEX])
        occluder.set_arrays(vertices, indices)
    elif mesh is QuadMesh:
        occluder = QuadOccluder3D.new()
        occluder.size = mesh.size
    elif mesh is BoxMesh:
        occluder = BoxOccluder3D.new()
        occluder.size = mesh.size
    elif mesh is SphereMesh:
        occluder = SphereOccluder3D.new()
        occluder.radius = mesh.radius
        var warning_string := (
            "%s's mesh is type SphereMesh. SphereOccluder3D has no "
            + " height component and may be inaccurate."
        )
        push_warning(warning_string % name)
    else:
        return null

    return occluder
