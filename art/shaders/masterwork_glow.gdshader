shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.784, 0.290, 1.0); // Gold amber
uniform float pulse_speed = 5.236; // 2 * PI / 1.2s approx 5.236 for 1.2 second period
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	if (base_color.a < 0.05) {
		COLOR = vec4(0.0);
	} else {
		// Breathing factor: oscillates between 0.2 and 1.0
		float pulse = 0.6 + 0.4 * sin(TIME * pulse_speed);
		vec3 boosted = base_color.rgb + (glow_color.rgb * pulse * glow_intensity * 0.4);
		COLOR = vec4(boosted, base_color.a);
	}
}
