shader_type canvas_item;

uniform float speed = 3.0;
uniform float frequency = 12.0;
uniform float amplitude = 0.005;

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.y * frequency) + (TIME * speed)) * amplitude;
	uv.x += wave * (1.0 - uv.y); // stronger near the top
	COLOR = texture(TEXTURE, uv);
}
