shader_type spatial;

const uint MAX_VP_TEXTURES = uint(10);
const bool DEBUG = false;

render_mode unshaded, cull_disabled;
//uniform sampler2D viewport_texture : source_color;
//uniform sampler2D viewport_texture_1 : source_color;
//uniform sampler2D viewport_texture_2 : source_color;
uniform sampler2D[MAX_VP_TEXTURES] viewport_textures : source_color;
uniform int iter = 0;

void fragment() {
    for (int i = 0; i < viewport_textures.length(); i++)
    {
        vec4 albedo_tex = texture(viewport_textures[i], SCREEN_UV);
        if (!(albedo_tex.r > 0.99 && albedo_tex.g < 0.001 && albedo_tex.b > 0.99))
        {
            ALBEDO = albedo_tex.rgb;
            break;
        }
        if (i == viewport_textures.length() - 1)
        {
            ALBEDO = vec3(DEBUG ? 1.0 : 0.0, 0.0, 0.0);
        }
    }
    //{
        //vec4 albedo_tex_1 = texture(viewport_texture_1, SCREEN_UV);
        //if (albedo_tex_1.r > 0.99 && albedo_tex_1.g < 0.001 && albedo_tex_1.b > 0.99)
        //{
            //vec4 albedo_tex_2 = texture(viewport_texture_2, SCREEN_UV);
            //ALBEDO = albedo_tex_2.rgb;
        //}
        //else
        //{
            //ALBEDO = albedo_tex_1.rgb;
        //}
    //}
    //else
    //{
        //ALBEDO = albedo_tex.rgb;
    //}
    //ALPHA = 1.0;
}
