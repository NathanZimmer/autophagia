shader_type sky;
uniform sampler2D sky_0;
uniform sampler2D sky_1;
uniform sampler2D weight;
const float motion = 0.025;

void sky() {
	vec4 color_0 = texture(sky_0, SKY_COORDS);
	vec4 color_1 = texture(sky_1, SKY_COORDS);
	vec4 mix_weight = texture(weight, SKY_COORDS + vec2(TIME * motion * 1.5, -1.0 * TIME * motion));
	COLOR = mix(color_0.rgb, color_1.rgb, mix_weight.x);
}
