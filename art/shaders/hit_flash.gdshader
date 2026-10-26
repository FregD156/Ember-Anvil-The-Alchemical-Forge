shader_type canvas_item;

uniform float hit_flash_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 hit_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (hit_flash_intensity > 0.0) {
		COLOR = mix(tex_color, vec4(hit_color.rgb, tex_color.a), hit_flash_intensity);
	} else {
		COLOR = tex_color;
	}
}
