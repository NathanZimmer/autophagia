@tool
class_name Portal extends MeshInstance3D
## TODO

var shader_path = 'res://shaders/portal.gdshader'
var player_in_portal = false
var on_screen = false

func set_material(viewport_texture: ViewportTexture) -> void:
	# Create material
	material_override = ShaderMaterial.new()
	material_override.shader = load(shader_path)
	material_override.resource_local_to_scene = true

	# Assign ViewportTexture
	material_override.set_shader_parameter('viewport_texture', viewport_texture)
	material_override.set_shader_parameter('color', Vector3(1.0, 0.0, 0.0))

func remove_material():
	material_override = null

func update_mesh(box_mesh, render_layer: int) -> void:
	mesh = box_mesh
	for i in range(1, 21): set_layer_mask_value(i, false)
	set_layer_mask_value(render_layer, true)
