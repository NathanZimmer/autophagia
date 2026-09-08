// CTR code modified from: https://godotshaders.com/shader/very-simple-crt-shader/
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms dithering_parameters;
uniform mat4 bayer_matrix = mat4(
    vec4(0.0, 0.5, 0.125, 0.625),
    vec4(0.75, 0.25, 0.875, 0.375),
    vec4(0.1875, 0.6875, 0.0625, 0.5625),
    vec4(0.9375, 0.4375, 0.8125, 0.3125)
);
// Bit depth of the above color palette
uniform int palette_bit_depth: hint_range(1, 8) = 1;
// Dithering intensity. Lower value means less noticable dither pattern, but 
// less visible information. Usually 255 / palette_bit_depth
uniform float threshold_scale : hint_range(0.0, 255) = 127.0;

group_uniforms crt_parameters;
uniform vec2 screen_resolution = vec2(427, 240);
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.01;
uniform float color_bleed_weight : hint_range(0.0, 1.0) = 0.2;


vec4 dither(vec2 screen_uv, vec4 frag_coord) 
{
    vec4 base_color = texture(screen_texture, screen_uv);
    ivec2 pos = ivec2(int(frag_coord.x) % 4, int(frag_coord.y) % 4);
    ivec3 scaled_color = ivec3(round(
            (base_color.rgb * 255.0 + threshold_scale * (bayer_matrix[pos.x][pos.y] - 0.5))));
    // Bit shift to fit within new color depth, normalized between 0 and 1
    vec3 shifted_normalized_color = vec3(
            (scaled_color >> (8 - palette_bit_depth))) / vec3(float((1 << palette_bit_depth) - 1));
    return vec4(shifted_normalized_color, 1.0);
}

vec4 crt(vec2 screen_uv, vec4 frag_coord) 
{
    vec4 adjacent_pixel_color_average = 
            dither(screen_uv - vec2(1.0 / screen_resolution.x, 0), frag_coord) * 0.5 
            + dither(screen_uv - vec2(0, 1.0 / screen_resolution.y), frag_coord) * 0.5;
    vec4 this_pixel_color = dither(screen_uv, frag_coord);
    
    return adjacent_pixel_color_average * color_bleed_weight + this_pixel_color;
}

vec4 crt_test(vec2 screen_uv, vec4 frag_coord) 
{
    //if (int(frag_coord.y) % 2 == 0)
    //{
        //if (frag_coord.y == screen_resolution.y)
        //{
            //return vec4(vec3(0.0), 1.0);
        //}
        //vec4 last_pixel_color = dither(
                //(frag_coord.xy - vec2(0.0, 1.0)) / screen_resolution, 
                //frag_coord - vec4(0.0, 1.0, 0.0, 0.0));
        //vec4 next_pixel_color = dither(
                //(frag_coord.xy + vec2(0.0, 1.0)) / screen_resolution, 
                //frag_coord + vec4(0.0, 1.0, 0.0, 0.0));
        //return mix((last_pixel_color + next_pixel_color) * 0.5, vec4(vec3(0), 1), 0.2);
    //}
    return dither(screen_uv, frag_coord);
}


vec4 average_3x3_grid(vec2 start_position)
{
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 3; i++)
    {
        for(int j = 0; j < 3; j++)
        {
            sum += texture(screen_texture, (start_position + vec2(float(i), float(j))) / vec2(960.0, 720.0)).rgb; 
        }
    }
    return vec4(sum / 9.0, 1.0);
}
void fragment() 
{
    //COLOR = crt_test(SCREEN_UV, FRAGCOORD);
    vec2 position_in_pixel = vec2(ivec2(FRAGCOORD.xy) % 3);
    vec4 color = average_3x3_grid(FRAGCOORD.xy - position_in_pixel);
    //COLOR = color;
    
    //COLOR = vec4(vec3(0), 1);
    COLOR = vec4(color.rgb * 0.7, color.a);
    COLOR[int(position_in_pixel.x)] = color[int(position_in_pixel.x)];
}
