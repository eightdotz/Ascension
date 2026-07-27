shader_type canvas_item;

// How much grayscale to apply.
// 0.0 = original colors
// 1.0 = full grayscale
uniform float grayscale : hint_range(0.0, 1.0) = 1.0;

// Contrast adjustment.
// 1.0 = normal
// <1.0 = lower contrast
// >1.0 = higher contrast
uniform float contrast : hint_range(0.0, 3.0) = 1.0;

// Required to sample the screen behind the ColorRect.
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
    vec4 screen = texture(screen_texture, SCREEN_UV);

    // Perceived luminance
    float gray = dot(screen.rgb, vec3(0.299, 0.587, 0.114));

    // Convert to grayscale
    vec3 color = mix(screen.rgb, vec3(gray), grayscale);

    // Contrast adjustment around 0.5
    color = (color - 0.5) * contrast + 0.5;

    COLOR = vec4(clamp(color, 0.0, 1.0), screen.a);
}