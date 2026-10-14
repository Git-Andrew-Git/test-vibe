shader_type canvas_item;

uniform float depth_ratio : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float depth = clamp(depth_ratio, 0.0, 1.0);
	float vignette = smoothstep(0.24, 0.92, length(SCREEN_UV - vec2(0.5)) * 1.12);
	vec3 deep_tint = vec3(0.008, 0.018, 0.105);
	float amount = depth * (0.28 + vignette * 0.19);
	COLOR = vec4(deep_tint, amount);
}
