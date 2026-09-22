shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture,
								   repeat_disable,
								   filter_nearest;
/**
 * Level of mix between original color and separated RGB channels. 0 is full
 * original, 1 is full separated.
 */
uniform float pixel_rgb_mix : hint_range(0, 1) = 0.15;
/**
 * Level of mix for scanlines (FRAGCOORD.y % 3 lines). 0 is black, 1 is no
 * scanline.
 */
uniform float scanline_darken_mix : hint_range(0, 1) = 0.6;
uniform vec3 scanline_color;

void fragment() {
	ivec2 position_in_pixel = ivec2(FRAGCOORD.xy) % 3;
	vec4 color = texture(screen_texture, SCREEN_UV);
	COLOR = vec4(vec3(0), 1);
	// top/bottom color
	float tb_color = max((color[position_in_pixel.x] * 3.0 - 1.0) * 0.5, 0);
	vec3 pixel_colors = vec3(
			tb_color, min(color[position_in_pixel.x] * 3.0, 1), tb_color);
	COLOR[position_in_pixel.x] = pixel_colors[position_in_pixel.y];
	COLOR = mix(color, COLOR, pixel_rgb_mix);
	int v_pos = int(FRAGCOORD.y);
	if (v_pos % 6 == 3 || v_pos % 6 == 4 || v_pos % 6 == 5) {
		COLOR = mix(COLOR, vec4(scanline_color, 1), scanline_darken_mix);
	}
}
