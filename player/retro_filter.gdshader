// Dithering code copied from https://godotshaders.com/shader/fake-floyd-stienberg-noise-dithering/
// CTR code copied from: https://godotshaders.com/shader/very-simple-crt-shader/
shader_type canvas_item;

group_uniforms dithering_parameters;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D  uTexBlueNoise;
uniform float contrast = 1.2;
uniform float brightness = 0.5;
uniform float uTime1 = 1;
uniform float uTime2 = 3.25;
uniform float uTime3 = 4;
uniform float colors = 16;

group_uniforms crt_parameters;
uniform vec2 screen_resolution = vec2(427, 240);
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.01;
uniform float color_bleed_weight : hint_range(0.0, 1.0) = 0.2;


float GetBlueNoiseDither( float grayscale, ivec2 pixelCoord, bool noise, vec2 ScreenUV )
{
    float blueNoiseValue = texture( uTexBlueNoise, vec2( ScreenUV.s, ScreenUV.t ) ).r;
    float blueNoiseValue2;
	float blueNoiseValue3;
	float blueNoiseValue4;
    if ( noise == true ) blueNoiseValue = sin( blueNoiseValue * 2.0 * 3.141592 + uTime1 ) * 0.5 + 0.5;
	if ( noise == true ) blueNoiseValue2 = sin( blueNoiseValue * 2.0 * 3.141592 + uTime2 ) * 0.5 + 0.5;
	if ( noise == true ) blueNoiseValue3 = sin( blueNoiseValue * 2.0 * 3.141592 + uTime3 ) * 0.5 + 0.5;
	if ( noise == true ) blueNoiseValue4 = 0.0;
    // Version 1
    //return blueNoiseValue < grayscale ? 1.0 : 0.0;

    // Version 2
    return (step( blueNoiseValue, grayscale ) + step( blueNoiseValue2, grayscale ) 
            + step( blueNoiseValue3, grayscale ) + step( blueNoiseValue4, grayscale ))/4.0;
}

mat4 contrastMatrix( float _contrast ){
	float t = ( 1.0 - _contrast ) / 2.0;
    return mat4(
		vec4(_contrast, 0, 0, 0),
		vec4(0, _contrast, 0, 0),
		vec4(0, 0, _contrast, 0),
		vec4(t, t, t, 1));
}

vec4 dither(vec2 screen_uv) {
    vec4 tex = texture(screen_texture, screen_uv);
	tex.r = round(tex.r*(colors))/colors;
	tex.g = round(tex.g*(colors))/colors;
	tex.b = round(tex.b*(colors))/colors;

	float ditherColorR = GetBlueNoiseDither( tex.r, ivec2( screen_uv.st ), true, screen_uv );
	float ditherColorG = GetBlueNoiseDither( tex.g, ivec2( screen_uv.st ), true, screen_uv );
	float ditherColorB = GetBlueNoiseDither( tex.b, ivec2( screen_uv.st ), true, screen_uv );
    
    return tex.rgba * (
        vec4(ditherColorR,ditherColorG,ditherColorB, 1.0) * contrastMatrix(contrast) + brightness
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

    return adjacent_pixel_color_average * color_bleed_weight + this_pixel_color 
            * (1.0 - color_bleed_weight) - vec4(vec3(color_dark_offset), 0);
}

void fragment() {
	COLOR = crt(SCREEN_UV);
}
