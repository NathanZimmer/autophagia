shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform sampler2D dither_viewport : source_color;
// Normalized 4 by 4 bayer matrix
uniform mat4 bayer_matrix_4x4 = mat4(
    vec4(0.0, 0.5, 0.125, 0.625),
    vec4(0.75, 0.25, 0.875, 0.375),
    vec4(0.1875, 0.6875, 0.0625, 0.5625),
    vec4(0.9375, 0.4375, 0.8125, 0.3125)
);
// Normalized 2 by 2 bayer matrix subdivided into 4x4
uniform mat4 bayer_matrix_2x2 = mat4(
    vec4(0.0, 0.0, 0.5, 0.5),
    vec4(0.0, 0.0, 0.5, 0.5),
    vec4(0.75, 0.75, 0.25, 0.25),
    vec4(0.75, 0.75, 0.25, 0.25)
);
//uniform sampler3D color_palette;
uniform sampler2D color_palette;
uniform int palette_bit_depth: hint_range(1, 8) = 1;
uniform float threshold_scale : hint_range(0.0, 255) = 0.0;

uniform vec2 screen_resolution = vec2(320, 240);
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.07;
uniform float color_bleed_weight : hint_range(0.0, 1.0) = 0.3;
uniform ivec2 mouse_delta;

float dither(float color, vec2 screen_uv, int dim) {
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (texture(dither_viewport, screen_uv).r - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

const vec2 RESOLUTION = vec2(640.0, 480.0);
const vec2 FOV = vec2(106.260200500488, 90.0);

float dither(float color, vec4 frag_coord, int dim) {
    ivec2 m_pos = ivec2(int(frag_coord.x) % 4, int(frag_coord.y) % 4);
    //ivec2 m_pos = ivec2((int(frag_coord.x) + mouse_delta.x) % 4, (int(frag_coord.y) + mouse_delta.y) % 4);
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (bayer_matrix_4x4[m_pos.x][m_pos.y] - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

vec4 dither(vec2 screen_uv) {
    vec4 color = texture(screen_texture, screen_uv);
    return vec4(
        dither(color.r, screen_uv, 0),
        dither(color.g, screen_uv, 1),
        dither(color.b, screen_uv, 2),
        color.a
    );
}
vec4 dither(vec2 screen_uv, vec4 frag_coord) {
    vec4 color = texture(screen_texture, screen_uv);
    //return vec4(
        //dither(color.r, frag_coord, 0),
        //dither(color.g, frag_coord, 1),
        //dither(color.b, frag_coord, 2),
        //color.a
    //);
    return vec4(
        dither(color.r, frag_coord, 0),
        dither(color.g, frag_coord, 1),
        dither(color.b, frag_coord, 2),
        color.a
    );
}

vec4 crt(vec2 screen_uv) {
    // Darken top halves of pixels
	float color_dark_offset = 0.0;
	int y_pos = int(floor(screen_uv.y * screen_resolution.y * 2.0));
    
	if (int(floor((float(y_pos) / 2.0))) * 2 == y_pos)
		color_dark_offset = scanline_intensity;
    vec4 adjacent_pixel_color_average = dither(screen_uv - vec2(1.0 / screen_resolution.x, 0))
            * 0.5 + dither(screen_uv - vec2(0, 1.0 / screen_resolution.y)) * 0.5;
    vec4 this_pixel_color = dither(screen_uv);
    //if (fract(TIME / 3.0 - screen_uv.y) < 0.005)
    //{
        //this_pixel_color *= 0.7;
    //}
    
    // TODO: Make this work when the screen is black
    return adjacent_pixel_color_average * color_bleed_weight + this_pixel_color
            * (1.0 - color_bleed_weight) - vec4(vec3(color_dark_offset), 0);
}

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);
    //COLOR.rgb = vec3(dither(color.r, FRAGCOORD), dither(color.g, FRAGCOORD), dither(color.b, FRAGCOORD));
    //COLOR.rgb = vec3(dither(color.r, SCREEN_UV), dither(color.g, SCREEN_UV), dither(color.b, SCREEN_UV));
    //COLOR.a = 1.0;
    //COLOR = crt(SCREEN_UV);
    //COLOR = dither(SCREEN_UV);
    COLOR = dither(SCREEN_UV, FRAGCOORD);
}
