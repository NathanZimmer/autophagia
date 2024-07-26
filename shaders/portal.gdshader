shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D viewport_texture : source_color;

void fragment() {
	vec4 albedo_tex = texture(viewport_texture, SCREEN_UV);
	ALBEDO = albedo_tex.rgb;
	//ALBEDO.r *= 1.5;
	ALPHA = 1.0; // Workaround to receive no post-processing
}
