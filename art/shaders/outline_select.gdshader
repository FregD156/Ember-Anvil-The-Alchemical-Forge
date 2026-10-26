shader_type canvas_item;

uniform bool outline_active = false;
uniform vec4 outline_color : source_color = vec4(1.0, 0.784, 0.290, 1.0); // Gold amber highlight
uniform float outline_width = 1.0;

void fragment() {
	vec4 base_color = texture(TEXTURE, UV);
	if (!outline_active) {
		COLOR = base_color;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
		float alpha = base_color.a;
		alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(0.0, size.y)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
		alpha = max(alpha, texture(TEXTURE, UV + vec2(size.x, 0.0)).a);

		if (base_color.a < 0.1 && alpha > 0.1) {
			COLOR = outline_color;
		} else {
			COLOR = base_color;
		}
	}
}
