shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 outline_color : source_color = vec4(1);
uniform vec4 hover_color : source_color = vec4(1);
uniform float line_thickness = 1.0;
uniform bool enabled = true;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness * 0.001;
    
    float outline = textureLod(screen_texture, SCREEN_UV + vec2(-size.x, 0), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(0, size.y), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(size.x, 0), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(0, -size.y), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(-size.x, size.y), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(size.x, size.y), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(-size.x, -size.y), 0.0).a;
	outline += textureLod(screen_texture, SCREEN_UV + vec2(size.x, -size.y), 0.0).a;
	outline = min(outline, 1.0);
	
	vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0);
    if (color.a > 0.0001) {
        color.rgb /= color.a;
        if (enabled) {
            color *= hover_color;
        }
    }
	color = mix(color, outline_color * float(enabled), (outline - color.a) * float(enabled));
    COLOR *= color;
}