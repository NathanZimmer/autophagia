shader_type canvas_item;
uniform sampler2D source_texture;
uniform float rotation_speed;

vec2 rotate(vec2 offset, vec2 center_of_rotation, float angle) {
	mat2 rotam = mat2(
		vec2(sin(angle), -cos(angle)),
		vec2(cos(angle), sin(angle))
	);

	vec2 rotation_offset = offset;
	rotation_offset -= center_of_rotation;
	rotation_offset *= rotam;
	rotation_offset += center_of_rotation;

	return rotation_offset;
}

void fragment() {
	vec2 offset = rotate(UV, vec2(0.5, 0.5), TIME * rotation_speed);
	COLOR = texture(source_texture, offset);
}