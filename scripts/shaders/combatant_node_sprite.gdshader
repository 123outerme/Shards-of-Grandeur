shader_type canvas_item;

/**
* Grayscale amount to blend current color to (0 = original color, 1 = fully grayscale)
*/
instance uniform float grayscale = 0.0;

//void vertex() {
//	// Called for every vertex the material is visible on.
//}

void fragment() {
	float colorAvg = (COLOR.x + COLOR.y + COLOR.z) / 3.0;
	COLOR = mix(COLOR, vec4(colorAvg, colorAvg, colorAvg, COLOR.a), clamp(grayscale, 0.0, 1.0));
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
