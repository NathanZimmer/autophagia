@tool
class_name Portal extends MeshInstance3D
## Mesh to be manipulated by a `PortalContainer`

var shader_path = "res://shaders/portal.gdshader"
var player_in_portal = false
var on_screen = false


## Create portal shader object and pass in viewport texture [br]
## `viewport_texture`: The viewport to be displayed by the portal's `ShaderMaterial`
func set_material(viewport_texture: ViewportTexture) -> void:
	# Create material
	material_override = ShaderMaterial.new()
	material_override.shader = load(shader_path)
	material_override.resource_local_to_scene = true

	# Assign ViewportTexture
	material_override.set_shader_parameter("viewport_texture", viewport_texture)
	material_override.set_shader_parameter("color", Vector3(1.0, 0.0, 0.0))


## Delete the portal's `ShaderMaterial`
func remove_material():
	material_override = null


## Update the mesh and render layer of this portal [br]
## `box_mesh`: the new box mesh for this portal [br]
## `render_layer`: the render layer that this portal will render to
func update_mesh(box_mesh: Mesh, render_layer: int) -> void:
	mesh = box_mesh
	for i in range(1, 21):
		set_layer_mask_value(i, false)
	set_layer_mask_value(render_layer, true)
