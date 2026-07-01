shader_type canvas_item;
uniform sampler2D screen_texture: hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size: hint_range(1.0, 100.0) = 4.0;
uniform float levels: hint_range(2.0, 32.0) = 6.0;
uniform float pivot: hint_range(0.0, 1.0) = 0.35;
uniform float shadow_crush: hint_range(0.0, 1.0) = 0.0;
uniform float highlight_boost: hint_range(0.0, 3.0) = 0.0;
uniform float flash_amount: hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_pivot: hint_range(0.0, 1.0) = 0.5;
uniform float flash_softness: hint_range(0.0, 0.5) = 0.05;

void fragment() {
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = tex_size / pixel_size;
	vec2 pixel_uv = floor(SCREEN_UV * pixel_count) / pixel_count;
	vec4 color = texture(screen_texture, pixel_uv);

	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));

	float shadow_factor = 1.0 - shadow_crush * (1.0 - smoothstep(0.0, pivot, luma));
	color.rgb *= shadow_factor;

	float highlight_factor = highlight_boost * smoothstep(pivot, 1.0, luma);
	color.rgb += (1.0 - color.rgb) * highlight_factor;

	color.rgb = clamp(color.rgb, 0.0, 1.0);
	color.rgb = floor(color.rgb * levels) / levels;

	float flash_luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float bw = smoothstep(flash_pivot - flash_softness, flash_pivot + flash_softness, flash_luma);
	vec3 flash_result = mix(vec3(0.0), flash_color.rgb, bw);
	color.rgb = mix(color.rgb, flash_result, flash_amount);

	COLOR = color;
}