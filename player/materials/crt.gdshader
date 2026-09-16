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

void fragment() {
  vec2 position_in_pixel = vec2(ivec2(FRAGCOORD.xy) % 3);
  vec4 color = texture(screen_texture, SCREEN_UV);
  COLOR = vec4(vec3(0), 1);
  // Normalize to height of pixel and clamp difference between 0 and 1 to get
  // this pixels color
  float normalized_color = color[int(position_in_pixel.x)] * 3.0;
  COLOR[int(position_in_pixel.x)] =
      clamp(normalized_color - position_in_pixel.y, 0, 1);
  COLOR = mix(color, COLOR, pixel_rgb_mix);
  if (int(position_in_pixel.y) % 3 == 0) {
    COLOR = mix(vec4(vec3(0), 1), COLOR, scanline_darken_mix);
  }
}
