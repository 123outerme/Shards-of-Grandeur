shader_type canvas_item;

/** Angle (in degrees) at which the weather particles will fall
*/
uniform float weather_direction_angle_degrees = 45.0;

/** Speed at which the weather particles will fall
*/
uniform float speed = 10.0;

/** Density of the particles on the screen
*/
uniform float density = 0.5;

/** A particle texture to use here
*/
uniform sampler2D particle;

/** The dimensions of the provided particle texture
*/
uniform vec2 particleDims;

varying vec2 vertex_position;
varying float finalAngleDeg;

// from auto-generated ParticleProcessMaterial => ShaderMaterial converted shader
uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

float calculate_position_weight(vec2 position) {
	float posX = cos(finalAngleDeg * PI / 180.0) * position.x;
	float posY = sin(finalAngleDeg * PI / 180.0) * position.y;
	float posXRotated = cos((finalAngleDeg + 90.0) * PI / 180.0) * position.x;
	float posYRotated = sin((finalAngleDeg + 90.0) * PI / 180.0) * position.y;
	return sin( (posX + posY + TIME * speed) * density ) * sin( (posXRotated + posYRotated) * density );
}

void vertex() {
	vertex_position = VERTEX;
	finalAngleDeg = weather_direction_angle_degrees + 180.0;
}

void fragment() {
	vec4 color = vec4(0, 0, 0, 0);
	
	/*
	float particlePos = calculate_position_weight(vertex_position, vec2(0, 0));
	if (abs(particlePos - 1.0) <= 0.01) {
		color = texture(particle, vec2(0, 0));
	}
	//*/
	//*
	for(int x = 0; x < int(particleDims.x); x++) {
		for (int y = 0; y < int(particleDims.y); y++) {
			float particlePos = calculate_position_weight(vertex_position - vec2(float(x), float(y)));
			//color = vec4(particlePos, 0, 0, 1);
			//*
			if (abs(particlePos - 1.0) <= 0.03) {
				color = texture(particle, vec2(float(x), float(y)));
			}
			//*/
		}
	}
	//*/
	COLOR = color;
}
