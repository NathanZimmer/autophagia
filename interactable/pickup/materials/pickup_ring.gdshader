shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec3 color : source_color;
uniform sampler2D scrolling_alpha_noise : source_color, filter_linear;
uniform float alpha_factor = 0.5;
uniform vec2 scroll_speed;

uniform float gradient_factor = 3.0;
uniform float gradient_offset = 0.8;

uniform float jitter: hint_range(0, 1) = 0.5;
uniform ivec2 resolution = ivec2(854, 480);

vec4 snap_to_position(vec4 base_position)
{
	vec4 snapped_position = base_position;
	snapped_position.xyz = base_position.xyz / base_position.w;

	vec2 snap_resulotion = floor(vec2(resolution) * (1.0 - jitter));
	snapped_position.x = floor(snap_resulotion.x * snapped_position.x) / snap_resulotion.x;
	snapped_position.y = floor(snap_resulotion.y * snapped_position.y) / snap_resulotion.y;

	snapped_position.xyz *= base_position.w;
	return snapped_position;
}

void vertex() {
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    POSITION = snapped_position;
}

void fragment() {
	vec2 offset = mod(UV + TIME * scroll_speed, 1.0);
    vec4 alpha_tex = texture(scrolling_alpha_noise, offset);
    float gradient = 1.0 - gradient_factor * pow(UV.y - gradient_offset, 2.0);
    ALBEDO = color;
    ALPHA = max(gradient, length(alpha_tex.rgb) * UV.y) * alpha_factor;
}