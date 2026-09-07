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
uniform float scale = 1.0;
uniform sampler2D texture_albedo : filter_nearest_mipmap_anisotropic;

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

varying vec3 uv1_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

float dither(float color, vec2 uv, int dim) {
    const vec2 step_factor = vec2(1.0, 1.0);
    const float scale_factor = 1.0;
    ivec2 m_pos = ivec2(
            int((step_factor.x * floor(uv.x / step_factor.x)) / scale_factor) % 4, 
            int((step_factor.y * floor(uv.y / step_factor.y)) / scale_factor) % 4);
    
    //ivec2 m_pos = ivec2(int(uv.x) % 4, int(uv.y) % 4);
    float bayer_factor = bayer_matrix_4x4[m_pos.x][m_pos.y];
    return bayer_factor;
    int scaled_color = int(round(
        (color * 255.0 + threshold_scale * (bayer_factor - 0.5))
    ));
    return texture(
        color_palette, 
        vec2(float((scaled_color >> (8 - palette_bit_depth))) / float((1 << palette_bit_depth) - 1), 0)
    )[dim];
}

vec4 dither(vec2 test, vec2 uv) {
    vec4 color = texture(texture_albedo, uv);
    //return color;
    return vec4(
        dither(color.r, test, 0),
        dither(color.g, test, 1),
        dither(color.b, test, 2),
        color.a
    );
}

varying vec2 angle_to_view;
void vertex() {
    //vec3 nvm = CAMERA_DIRECTION_WORLD;
    //vec3 local_normal = NORMAL;
    //angle_to_view = vec3(
        //abs(dot(nvm, vec3(local_normal.x, 1.0, 1.0))),
        //abs(dot(nvm, vec3(1.0, local_normal.y, 1.0))),
        //abs(dot(nvm, vec3(1.0, 1.0, local_normal.z)))
    //);
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    //angle_to_view = vec3(
            //acos(dot(normalize(NORMAL.xz), vec2(0.0, -1.0))) / TAU,
            //0.0 * acos(dot(normalize(NORMAL.yz), vec2(0.0, -1.0))) / TAU,
            //0.0);
    angle_to_view = abs(NORMAL.xy);
    
    vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
    // UV1 Triplanar: Enabled (with World Triplanar)
	uv1_power_normal = pow(abs(normal), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
    vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
    //ALBEDO = albedo_tex.rgb;
    //const float depth = length(VERTEX);
    
    //const vec2 angle_to_center = vec2(
            //abs(SCREEN_UV.x - 0.5) * H_FOV_DEG,
            //abs(SCREEN_UV.y - 0.5) * V_FOV_DEG);
    //const vec2 corrected_depth = vec2(
            //cos(radians(angle_to_center.x)) / depth,
            //cos(radians(angle_to_center.y)) / depth);
    
    //vec2 vertex_x = vec2(VERTEX.x, VERTEX.z);
    //vec2 view_x = vec2(VIEW.x, VIEW.z);
    //vec2 vertex_y = vec2(VERTEX.y, VERTEX.z);
    //vec2 view_y = vec2(VIEW.y, VIEW.z);
    //float x_angle_to_center = cos(dot(vertex_x, view_x));
    //float y_angle_to_center = cos(dot(vertex_y, view_y));
    //vec2 corrected_depth = vec2(
            //length(vertex_x) * cos(x_angle_to_center),
            //length(vertex_y) * cos(y_angle_to_center));
    //ALBEDO = vec3(x_angle_to_center, y_angle_to_center, 0.0);
    //float x_angle_to_center = acos(dot(-VIEW.xz, vec2(0.0, -1.0))) / TAU;
    //float y_angle_to_center = acos(dot(VIEW.yz, vec2(0.0, -1.0))) / TAU;
    //ALBEDO = vec3(x_angle_to_center, 0.0, 0.0);
    
    //vec2 dir = abs(RESOLUTION * 0.5 - SCREEN_UV * RESOLUTION);
    //ALBEDO = vec3(pow(atan(dir.x) / TAU, 2.0), 0.0, 0.0);
    //vec2 center = vec2(0.5, 0.5);
    //vec2 pos = SCREEN_UV - center;
    //pos.x *= VIEWPORT_SIZE.x / VIEWPORT_SIZE.y; 
    //float angle = atan(pos.y, pos.x); 
    //ALBEDO = vec3(abs(angle) / TAU);
    
    float depth = length(VERTEX);
    float x_angle = acos(dot(normalize(VERTEX.xz), vec2(0.0, -1.0)));
    float y_angle = acos(dot(normalize(VERTEX.yz), vec2(0.0, -1.0)));
    vec2 corrected_depth = vec2(length(VERTEX.xz) * cos(x_angle), length(VERTEX.yz) * cos(y_angle));
    //vec2 stepped_depth = pow(vec2(2.0, 2.0), floor(log2(vec2(depth, depth))));
    //float mix_factor = (depth - stepped_depth.x) / stepped_depth.x;
    vec2 stepped_depth = pow(vec2(2.0, 2.0), floor(log2(corrected_depth)));
    float mix_factor = (length(corrected_depth) - length(stepped_depth)) / length(stepped_depth);
    // FIXME: Why does the pixel stretching on the floor move along the world z instead of local z??
    vec2 pixel_size_world = vec2(
            (1.0 / stepped_depth.x) * H_ANGLE_FACTOR_DEG * (1.0 - /*angle_to_view.x*/ 0.0),
            (1.0 / stepped_depth.y) * V_ANGLE_FACTOR_DEG * (1.0 - /*angle_to_view.y*/ 0.0));
    vec2 pixel_size_world_x2 = vec2(
            (1.0 / stepped_depth.x) * H_ANGLE_FACTOR_DEG * 0.5 * (1.0 - /*angle_to_view.x*/ 0.0),
            (1.0 / stepped_depth.y) * V_ANGLE_FACTOR_DEG * 0.5 * (1.0 - /*angle_to_view.y*/ 0.0));
    
    ALBEDO = mix(dither(vec2((pixel_size_world.x * UV.x * scale), (pixel_size_world.y * UV.y * scale)), UV).rgb,
            dither(vec2((pixel_size_world_x2.x * UV.x * scale), (pixel_size_world_x2.y * UV.y * scale)), UV).rgb,
            mix_factor);
            
    //ALBEDO *= vec3(angle_to_view, 0.0);
    
    //ALBEDO = vec3(x_angle, y_angle, 0.0);
    //ALBEDO = vec3(length(VERTEX.xz) * cos(x_angle), length(VERTEX.yz) * cos(y_angle), 0.0);
    //vec2 pixel_world_size = vec2(
            //(1.0 / corrected_depth.x) * H_ANGLE_FACTOR_DEG,
            //(1.0 / corrected_depth.y) * V_ANGLE_FACTOR_DEG);
    //ALBEDO = dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb;
    
    ////const float factored_depth = pow(2.0, floor(log2(depth)));
    //const float factored_depth = depth;
    ////const float mix_factor = sin(((depth - factored_depth) / factored_depth) * (PI / 2.0));
    //const float mix_factor = (depth - factored_depth) / factored_depth;
    //
    ////float angle_x = abs(dot(vec3(VIEW.x, 0.0, 0.0), normal));
    ////float angle_y = abs(dot(vec3(0.0, VIEW.y, 0.0), normal));
    ////float angle_z = abs(dot(vec3(0.0, VIEW.z, 0.0), normal));
    ////const float skew_scale_factor = 100.0;
    //
    //vec2 pixel_world_size = vec2(
            //(1.0 / corrected_depth.x) * H_ANGLE_FACTOR_DEG, // * (2.0 - angle_x),
            //(1.0 / corrected_depth.y) * V_ANGLE_FACTOR_DEG);
    //vec2 pixel_world_size_x2 = vec2(
            //(1.0 / factored_depth) * H_ANGLE_FACTOR_DEG * 0.5, // * (2.0 - angle_x),
            //(1.0 / factored_depth) * V_ANGLE_FACTOR_DEG * 0.5);
            //
    ////ALBEDO = dither(vec2(
                ////(mix(pixel_world_size.x, pixel_world_size_x2.x, mix_factor) * UV.x), 
                ////(mix(pixel_world_size.y, pixel_world_size_x2.y, mix_factor) * UV.y)), UV).rgb;
    ////ALBEDO = mix(dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb,
            ////dither(vec2((pixel_world_size_x2.x * UV.x), (pixel_world_size_x2.y * UV.y)), UV).rgb,
            ////mix_factor);
    //
    ////ALBEDO = mix(dither(vec2((pixel_world_size.x * UV.x * scale), (pixel_world_size.y * UV.y * scale)), UV).rgb,
            ////dither(vec2((pixel_world_size_x2.x * UV.x * scale), (pixel_world_size_x2.y * UV.y * scale)), UV).rgb,
            ////mix_factor);
            //
    ////float angle_to_normal_x = dot(NORMAL, VIEW * VIEW_MATRIX[0].xyz);
    ////float angle_to_normal_y = dot(NORMAL, VIEW * VIEW_MATRIX[1].xyz);
    //
    ////ALBEDO = dither(vec2((pixel_world_size.x * UV.x), (pixel_world_size.y * UV.y)), UV).rgb;
    ////vec4 color = texture(texture_albedo, pixel_world_size);
    ////ALBEDO = color.rgb;
    ////ALPHA = color.a;
    ////const float scaled_depth = pow((1.0 / depth), 3.0);
    ////ALBEDO = vec3(depth / 100.0);
}

//
//void fragment() {
    //ALBEDO = dither(UV, length(VERTEX)).rgb;
    ////ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
//}
