shader_type spatial; 
render_mode unshaded, fog_disabled; 
uniform sampler2D screen_texture : hint_screen_texture; 
uniform float pixel_size : hint_range(0.0, 100.0, 0.1) = 1.0; 
void fragment() { 
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = tex_size / pixel_size; 
	vec2 pixel_uv = floor(SCREEN_UV * pixel_count) / pixel_count; 
	vec4 color = texture(screen_texture, pixel_uv); ALBEDO = color.rgb; 
	}