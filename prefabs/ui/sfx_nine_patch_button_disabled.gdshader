shader_type canvas_item;

uniform bool disabled = false;
const float shadeAmount = 0.25;

void fragment() {
	COLOR = texture(TEXTURE, UV); // Read from texture
	if (disabled) {
		COLOR -= vec4(1.0 * shadeAmount, 1.0 * shadeAmount, 1.0 * shadeAmount, 0.0);
	}
}
