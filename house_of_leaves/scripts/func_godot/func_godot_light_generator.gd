@tool
extends Node
## Uses `_func_godot_build_complete` to create a light node based on the properties from the custom TrenchBroom light class

enum {
	SPOT_LIGHT_3D,
	OMNI_LIGHT_3D,
}

@export var func_godot_properties: Dictionary


func _func_godot_build_complete():
	if not func_godot_properties["generate_light_node"]:
		return

	var light: Light3D
	match func_godot_properties["light_node"]:
		OMNI_LIGHT_3D:
			light = OmniLight3D.new()
		SPOT_LIGHT_3D:
			light = SpotLight3D.new()
	add_child(light)
	light.owner = owner
	light.hide()

	light.position = func_godot_properties["offset"]
	light.rotation = func_godot_properties["rotation"]

	for property in func_godot_properties:
		var val = func_godot_properties[property]
		light.set(property, val)
