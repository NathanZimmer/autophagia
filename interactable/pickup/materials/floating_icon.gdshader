shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;
uniform sampler2D texture_albedo : source_color, filter_linear;
uniform vec3 uv_scale;
uniform vec2 uv_offset;
uniform float rotation_speed = -1.0;
uniform float tilt = 1.885;
uniform float bounce_speed = 1.25;
uniform float bounce_distance = 0.15;

//uniform float jitter: hint_range(0, 1) = 0.5;
uniform ivec2 resolution = ivec2(320, 240);

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

//vec4 snap_to_position(vec4 base_position)
//{
	//vec4 snapped_position = base_position;
	//snapped_position.xyz = base_position.xyz / base_position.w;
//
	//vec2 snap_resulotion = floor(vec2(resolution) * (1.0 - jitter));
	//snapped_position.x = floor(snap_resulotion.x * snapped_position.x) / snap_resulotion.x;
	//snapped_position.y = floor(snap_resulotion.y * snapped_position.y) / snap_resulotion.y;
//
	//snapped_position.xyz *= base_position.w;
	//return snapped_position;
//}

void vertex() {
    VERTEX.xy = rotate(VERTEX.xy, vec2(0.0, 0.0), tilt);
    VERTEX.xz = rotate(VERTEX.xz, vec2(0.0, 0.0), TIME * rotation_speed);
    VERTEX.y = VERTEX.y + bounce_distance * sin(TIME * bounce_speed);
    
	 vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    // pre screen space "Normalized Device Coordinates"
    vec2 ndc = clip_pos.xy / clip_pos.w;
    vec2 screen_pos = ((ndc * 0.5) + 0.5) * vec2(resolution);
    screen_pos = floor(screen_pos + 0.5);
    vec2 snapped_ndc = ((screen_pos / vec2(resolution)) - 0.5) * 2.0;
    clip_pos.xy = snapped_ndc * clip_pos.w;
    POSITION = clip_pos;
    
	UV = UV * uv_scale.xy + uv_offset.xy;
}

void fragment() {    
    vec4 albedo_tex = texture(texture_albedo, UV);
    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;
}