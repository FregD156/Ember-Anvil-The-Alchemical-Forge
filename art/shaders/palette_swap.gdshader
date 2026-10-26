shader_type canvas_item;

// 4-tone palette swap via ramp or LUT
uniform sampler2D palette_lut : filter_nearest;
uniform bool use_lut = false;
uniform vec4 color_dark : source_color = vec4(0.165, 0.141, 0.220, 1.0);
uniform vec4 color_mid_dark : source_color = vec4(0.420, 0.373, 0.494, 1.0);
uniform vec4 color_mid_light : source_color = vec4(0.604, 0.561, 0.639, 1.0);
uniform vec4 color_light : source_color = vec4(0.949, 0.922, 0.867, 1.0);

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	if (base_color.a < 0.01) {
		COLOR = vec4(0.0);
	} else if (use_lut) {
		float luma = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
		COLOR = texture(palette_lut, vec2(luma, 0.5));
		COLOR.a *= base_color.a;
	} else {
		float luma = dot(base_color.rgb, vec3(0.299, 0.587, 0.114));
		if (luma < 0.25) {
			COLOR = vec4(color_dark.rgb, base_color.a);
		} else if (luma < 0.5) {
			COLOR = vec4(color_mid_dark.rgb, base_color.a);
		} else if (luma < 0.75) {
			COLOR = vec4(color_mid_light.rgb, base_color.a);
		} else {
			COLOR = vec4(color_light.rgb, base_color.a);
		}
	}
}
