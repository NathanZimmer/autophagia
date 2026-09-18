shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture,
								   repeat_disable,
								   filter_nearest;
/**
 * Bit depth of the above color palette
 */
uniform int palette_bit_depth : hint_range(1, 8) = 1;
/**
 * Dithering intensity. Lower value means less noticable dither pattern, but
 * less visible information. Usually 255 / palette_bit_depth
 */
uniform float threshold_scale : hint_range(0.0, 255) = 255.0;
//uniform float bleed_weight : hint_range(0.0, 1.0);

const mat4 bayer_matrix = mat4(
		vec4(0.0, 0.5, 0.125, 0.625), vec4(0.75, 0.25, 0.875, 0.375),
		vec4(0.1875, 0.6875, 0.0625, 0.5625), vec4(0.9375, 0.4375, 0.8125, 0.3125));

vec4 dither(vec2 screen_uv, vec4 frag_coord) {
	vec4 base_color = texture(screen_texture, screen_uv);
	if (base_color.a <= 0.1) {
		return vec4(vec3(0), 0);
	}
	ivec2 pos = ivec2(int(frag_coord.x) % 4, int(frag_coord.y) % 4);
	ivec3 scaled_color =
			ivec3(round((base_color.rgb * 255.0 +
					threshold_scale * (bayer_matrix[pos.x][pos.y] - 0.5))));
	// Bit shift to fit within new color depth, normalized between 0 and 1
	vec3 shifted_normalized_color =
			vec3((scaled_color >> (8 - palette_bit_depth))) /
			vec3(float((1 << palette_bit_depth) - 1));
	return vec4(shifted_normalized_color, 1.0);
}

void fragment() {
	//vec4 adj_average =
			//(dither(SCREEN_UV - vec2(1.0 / 640.0, 0), FRAGCOORD - vec4(1, 0, 0, 0)) +
					//dither(SCREEN_UV - vec2(0, 1.0 / 480.0), FRAGCOORD - vec4(0, 1, 0, 0))) *
			//0.5;
	//COLOR = dither(SCREEN_UV, FRAGCOORD) * (1.0 - bleed_weight) +
			//adj_average * bleed_weight;
    COLOR = dither(SCREEN_UV, FRAGCOORD);
}
