shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform sampler2D texture_albedo : source_color, filter_linear;
uniform vec2 uv_offset;
uniform float rotation_speed;

uniform vec3 uv_scale;
uniform float jitter: hint_range(0, 1) = 0.5;
uniform ivec2 resolution = ivec2(854, 480);

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
    VERTEX.xy = rotate(VERTEX.xy, vec2(0.0, 0.0), PI * 0.08);
    VERTEX.xz = rotate(VERTEX.xz, vec2(0.0, 0.0), TIME * rotation_speed);
	vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    POSITION = snapped_position;
	UV = UV * uv_scale.xy + uv_offset.xy;
}

void fragment() {    
    vec4 albedo_tex = texture(texture_albedo, UV);
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;
}