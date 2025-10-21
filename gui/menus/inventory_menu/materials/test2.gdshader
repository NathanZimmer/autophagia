shader_type canvas_item;
uniform sampler2D source_texture;
uniform sampler2D offset_texture;
uniform vec2 scale;
uniform vec2 offset;
uniform bool flip;

void fragment() {
    vec4 test = texture(offset_texture, flip ? vec2(1.0 - UV.x, 1.0 - UV.y) : UV);
	vec2 tex_offset = vec2(UV.x, UV.y + test.r);
	COLOR = texture(source_texture, tex_offset * scale + offset);
    if ((tex_offset.y * scale.y + offset.y) > 1.0 || (tex_offset.y * scale.y + offset.y) < 0.0) {
        discard;
    }
}