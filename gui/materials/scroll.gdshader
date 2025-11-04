shader_type canvas_item;
//uniform sampler2D source_texture;
uniform vec2 scroll_speed;

void fragment() {
	vec2 offset = mod(UV + TIME * scroll_speed, 1.0);
	COLOR = texture(TEXTURE, offset);
}