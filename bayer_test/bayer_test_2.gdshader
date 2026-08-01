shader_type spatial;

// There are a few problems left to solve:
// 1. Fix the shimmering from looking at faces on an angle
// 2. Find a better solution to the scale issue than just using the same UV2 scale for all objects. 
// 3. Add averaging of all texture pixels under the dither pixel
// 4. Fix dither color not working right

// Basically, I need to find a solution to this problem that doesn't involve using using the UV 
// shader var. It skews at an angle and is not uniform between objects
// In addition to that, I need to figure out how to average the colors beneath each dither pixel


// Constants for test
const float H_FOV_DEG = 106.260200500488;
const float V_FOV_DEG = 90.0;
const vec2 RESOLUTION = vec2(640.0, 480.0);
const float H_ANGLE_FACTOR_DEG = RESOLUTION.x / 1.33333323133; // tan(H_FOV / 2.0)
const float V_ANGLE_FACTOR_DEG = RESOLUTION.y / 1.0; // tan(V_FOV / 2.0) 
const float NEAR = 0.05;
const float FAR = 20.0;
//const vec2 PIXEL_SIZE_NEAR = vec2(38400.57166009417, 9600.0);
//const vec2 PIXEL_SIZE_FAR = vec2(96.00142915023542, 24.0);
//const vec2 PIXEL_SIZE_NEAR = vec2(96.00142915023542, 24.0);
//const vec2 PIXEL_SIZE_FAR = vec2(38400.57166009417, 9600.0);

uniform sampler2D albedo_texture : filter_nearest_mipmap_anisotropic;

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

float dither(float color, vec2 uv, int dim) {
    const vec2 step_factor = vec2(1.0, 1.0);
    const float scale_factor = 1.0;
    ivec2 m_pos = ivec2(
            int((step_factor.x * floor(uv.x / step_factor.x)) / scale_factor) % 4, 
            int((step_factor.y * floor(uv.y / step_factor.y)) / scale_factor) % 4);
    
    //ivec2 m_pos = ivec2(int(uv.x) % 4, int(uv.y) % 4);
    float bayer_factor = bayer_matrix_4x4[m_pos.x][m_pos.y];
    //return bayer_factor;
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (bayer_factor - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

vec4 dither(vec2 test, vec2 uv) {
    vec4 color = texture(albedo_texture, uv);
    //return color;
    return vec4(
        dither(color.r, test, 0),
        dither(color.g, test, 1),
        dither(color.b, test, 2),
        color.a
    );
}

void fragment() {
    const float depth = length(VERTEX);
    
    //const vec2 angle_to_center = vec2(
            //abs(SCREEN_UV.x - 0.5) * H_FOV_DEG,
            //abs(SCREEN_UV.y - 0.5) * V_FOV_DEG);
    //const vec2 corrected_depth = vec2(
            //cos(radians(angle_to_center.x)) / depth,
            //cos(radians(angle_to_center.y)) / depth);
    
    const float factored_depth = pow(2.0, floor(log2(depth)));
    //const float mix_factor = sin(((depth - factored_depth) / factored_depth) * (PI / 2.0));
    const float mix_factor = (depth - factored_depth) / factored_depth;
    
    const vec2 pixel_world_size = vec2(
            (1.0 / factored_depth) * H_ANGLE_FACTOR_DEG,
            (1.0 / factored_depth) * V_ANGLE_FACTOR_DEG);
    const vec2 pixel_world_size_x2 = vec2(
            (1.0 / factored_depth) * H_ANGLE_FACTOR_DEG * 0.5,
            (1.0 / factored_depth) * V_ANGLE_FACTOR_DEG * 0.5);
            
    //ALBEDO = dither(vec2(
                //(mix(pixel_world_size.x, pixel_world_size_x2.x, mix_factor) * UV.x), 
                //(mix(pixel_world_size.y, pixel_world_size_x2.y, mix_factor) * UV.y)), UV).rgb;
    //ALBEDO = mix(dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb,
            //dither(vec2((pixel_world_size_x2.x * UV.x), (pixel_world_size_x2.y * UV.y)), UV).rgb,
            //mix_factor);
    ALBEDO = mix(dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb,
            dither(vec2((pixel_world_size_x2.x * UV.x), (pixel_world_size_x2.y * UV.y)), UV).rgb,
            mix_factor);
    //ALBEDO = dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb;
    //vec4 color = texture(albedo_texture, pixel_world_size);
    //ALBEDO = color.rgb;
    //ALPHA = color.a;
    //const float scaled_depth = pow((1.0 / depth), 3.0);
    //ALBEDO = vec3(depth / 100.0);
}

//
//void fragment() {
    //ALBEDO = dither(UV, length(VERTEX)).rgb;
    ////ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
//}
