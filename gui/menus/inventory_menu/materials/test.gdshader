shader_type canvas_item;
uniform sampler2D source_texture;
uniform sampler2D offset_texture;
uniform float peak_offset;
uniform bool flip;

void fragment() {
    vec4 test = texture(offset_texture, flip ? vec2(1.0 - UV.x, 1.0 - UV.y) : UV);
	vec2 tex_offset = vec2(UV.x, UV.y + test.r);
    //vec2 scale_test = vec2(1.0 / scale.x, 1.0 / scale.y);
	//COLOR = texture(source_texture, tex_offset * scale_test + offset);
    //if ((tex_offset.y * scale_test.y + offset.y) > 1.0 || (tex_offset.y * scale_test.y + offset.y) < 0.0) {
        //discard;
    //}
    float y_scale = 1.0 - peak_offset;
    vec2 offset = vec2(tex_offset.x, (tex_offset.y * (1.0 / y_scale)) - ((1.0 / y_scale) - 1.0));
	COLOR = texture(source_texture, offset);
    if ((offset.y) > 1.0 || (offset.y) < 0.0) {
        discard;
    }
}