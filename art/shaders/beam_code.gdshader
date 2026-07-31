shader_type spatial;
render_mode blend_mix, depth_draw_opaque, depth_test_default, cull_disabled, diffuse_lambert, specular_schlick_ggx, unshaded;

void fragment() {
    vec4 color = vec4(0.0, 0.0, 1.0, 1.0);
    ALBEDO = color.rgb;
}
