// NOTE: Shader automatically converted from Godot Engine 4.4.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_nearest, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform bool enable_ambient_occlusion = false;
uniform sampler2D texture_ambient_occlusion : hint_default_white, filter_nearest, repeat_enable;
uniform vec4 ao_texture_channel;
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01);

uniform ivec2 resolution = ivec2(854, 480);

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
	//vec4 snapped_position = snap_to_position(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    //POSITION = snapped_position;
    
    vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    // pre screen space "Normalized Device Coordinates"
    vec2 ndc = clip_pos.xy / clip_pos.w;
    vec2 screen_pos = ((ndc * 0.5) + 0.5) * vec2(resolution);
    screen_pos = floor(screen_pos + 0.5);
    vec2 snapped_ndc = ((screen_pos / vec2(resolution)) - 0.5) * 2.0;
    clip_pos.xy = snapped_ndc * clip_pos.w;
    POSITION = clip_pos;
}

void fragment() {
	vec2 base_uv = UV;
	vec2 base_uv2 = UV2;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
    //ALBEDO *= 255.0;
    //ALBEDO = floor(ALBEDO /= 8.0);
    //ALBEDO /= 31.0;
    //float steps = 32.0;
    //vec3 quantized_color;
    //quantized_color.r = floor(ALBEDO.r * steps) / (steps - 1.0);
    //quantized_color.g = floor(ALBEDO.g * steps) / (steps - 1.0);
    //quantized_color.b = floor(ALBEDO.b * steps) / (steps - 1.0);
    //ALBEDO = quantized_color;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	// Ambient Occlusion: Enabled
    if (enable_ambient_occlusion) {
        AO = dot(texture(texture_ambient_occlusion, base_uv2), ao_texture_channel);
        AO_LIGHT_AFFECT = ao_light_affect;
    }
}
