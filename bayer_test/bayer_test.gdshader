shader_type spatial;

// TODO: 
// * Figure out how to average UV coord colors to fit into matrix pattern
// * Figure out how many layers of depth are needed, linearly space between min and max depth and 
//   distance + remainder to interpolate between each layer
// Ex: 10 layers with a depth of 10. if dist is 3.5 then we use layer 3 and blend 50% into layer 4

uniform sampler2D albedo_texture : filter_nearest_mipmap_anisotropic;
uniform sampler2D depth_texture : hint_depth_texture;

uniform mat4 bayer_matrix_4x4 = mat4(
    vec4(0.0, 0.5, 0.125, 0.625),
    vec4(0.75, 0.25, 0.875, 0.375),
    vec4(0.1875, 0.6875, 0.0625, 0.5625),
    vec4(0.9375, 0.4375, 0.8125, 0.3125)
);
uniform mat2 bayer_matrix_2x2 = mat2(
    vec2(0.0, 0.5),
    vec2(0.75, 0.25)
);

//uniform sampler3D color_palette;
uniform sampler2D color_palette;
uniform int palette_bit_depth: hint_range(1, 8) = 1;
uniform float threshold_scale : hint_range(0.0, 255) = 0.0;

float dither(float color, vec2 uv, int dim, float depth) {
    ivec2 m_pos = ivec2(int(uv.x * 100.0) % 4, int(uv.y * 100.0) % 4);
    ivec2 m_pos_2 = ivec2(int(uv.x * 100.0) % 2, int(uv.y * 100.0) % 2);
    float bayer_factor = mix(bayer_matrix_4x4[m_pos.x][m_pos.y], bayer_matrix_2x2[m_pos_2.x][m_pos_2.y], depth * 3.0);
    return (bayer_factor);
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (bayer_factor - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

vec4 dither(vec2 uv, float depth) {
    vec4 color = texture(albedo_texture, uv);
    return vec4(
        dither(color.r, uv, 0, depth),
        dither(color.g, uv, 1, depth),
        dither(color.b, uv, 2, depth),
        color.a
    );
}

void fragment() {
    ALBEDO = dither(UV, length(VERTEX)).rgb;
    //ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
}
