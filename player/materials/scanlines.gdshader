shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture,
								   repeat_disable,
								   filter_nearest;
uniform float bleed_weight : hint_range(0.0, 1.0);
uniform float scanline_weight : hint_range(0.0, 1.0);

void fragment() {
	vec4 adj_average =
			(texture(screen_texture, SCREEN_UV - vec2(1.0 / 640.0, 0)) +
					texture(screen_texture, SCREEN_UV - vec2(0, 1.0 / 480.0))) *
			0.5;
	COLOR = texture(screen_texture, SCREEN_UV) * (1.0 - bleed_weight) +
			adj_average * bleed_weight;
	if (int(FRAGCOORD.y) % 2 == 1) {
		COLOR = mix(COLOR, vec4(vec3(0), 1), scanline_weight);
	}
}
