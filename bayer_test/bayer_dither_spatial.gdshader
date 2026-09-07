shader_type spatial;
render_mode unshaded, fog_disabled;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Normalized 4 by 4 bayer matrix
uniform mat4 bayer_matrix_4x4 = mat4(
    vec4(0.0, 0.5, 0.125, 0.625),
    vec4(0.75, 0.25, 0.875, 0.375),
    vec4(0.1875, 0.6875, 0.0625, 0.5625),
    vec4(0.9375, 0.4375, 0.8125, 0.3125)
);
//uniform sampler3D color_palette;
uniform sampler2D color_palette;
uniform int palette_bit_depth: hint_range(1, 8) = 1;
uniform float threshold_scale : hint_range(0.0, 255) = 0.0;

const vec2 RESOLUTION = vec2(640.0, 480.0);
const vec2 FOV = vec2(106.260200500488, 90.0);

float dither(float color, vec2 frag_coord, int dim) {
    ivec2 m_pos = ivec2(int(frag_coord.x) % 4, int(frag_coord.y) % 4);
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (bayer_matrix_4x4[m_pos.x][m_pos.y] - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

vec4 dither(vec2 screen_uv, vec4 frag_coord, vec2 angle_to_world_forward) {
    vec2 offset = vec2(degrees(angle_to_world_forward.x) * (FOV.x / RESOLUTION.x), 0.0);
    vec4 color = texture(screen_texture, screen_uv);
    return vec4(
        dither(color.r, offset, 0),
        dither(color.g, offset, 1),
        dither(color.b, offset, 2),
        color.a
    );
}

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec3 forward = normalize((INV_VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xyz);
    vec2 angle_to_world_forward = vec2(
        acos(dot(forward.xz, vec2(0.0, -1.0))),
        acos(dot(forward.yz, vec2(0.0, -1.0)))
    );
    //ALBEDO = vec3(angle_to_world_forward.x, 0.0, 0.0);
        
    vec4 color = -dither(SCREEN_UV, FRAGCOORD, angle_to_world_forward);
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
