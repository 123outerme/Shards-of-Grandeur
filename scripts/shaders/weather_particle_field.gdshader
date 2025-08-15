shader_type canvas_item;

// CC0 licensed source: https://github.com/MMqd/uint-shader-hash
#include "res://scripts/shaders/uint_hash.gdshaderinc"

/** Angle (in degrees) at which the weather particles will fall
*/
uniform float weather_direction_angle_degrees = 45.0;

/** NOTE: not currently functional. The angle range (in degrees) at which `weather_direction_angle_degrees` will randomly vary per particle
*/
//uniform float weather_direction_angle_rand_range = 2.0;

/** Speed at which the weather particles move in the chosen direction
*/
uniform float speed = 10.0;

/** Range at which the `speed` will randomly vary based on the specific particle
*/
//uniform float speed_rand_range = 0.5;

/** Spacing (in pixels) between individual particles; approximate density of particles
*/
uniform ivec2 particleSpacing = ivec2(4, 4);

/** The max distance (in pixels) that each particle may be randomly displaced in a particular direction; a translation overflowing the particle's cell will wrap around
*/
uniform float positionRandRange = 3;

/** A particle texture to use here
*/
uniform sampler2D particle1;

/** A particle texture to use here
*/
uniform sampler2D particle2;


/** A particle texture to use here
*/
uniform sampler2D particle3;


/** A particle texture to use here
*/
uniform sampler2D particle4;

/** The dimensions of the provided particle textures
*/
uniform ivec2 particleDims = ivec2(2, 2);

/** Integer (pixel) scaling of the particle textures; note that a higher number DOES incur a higher processing time cost
*/
uniform int particleScale = 1;

varying vec2 vertex_position;
varying float motionAngleRad;

highp vec2 floatHashVec2ToVec2(in highp vec2 f) {
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);

    highp uint h = 2u; // 2 outputs

    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);

    return vec2(
        uintTo01Float(hashUint(h + fx, MAGIC_NUMBERS[0])),
        uintTo01Float(hashUint(h + fy, MAGIC_NUMBERS[1]))
    );
}

/** It seems that in my testing, -1 % 3 == -1, not 2 (on at least my hardware); this fixes that portably
 See: https://www.geeksforgeeks.org/c/modulus-on-negative-numbers/
*/
int negativeOkModulus(int a, int b) {
	return ((a % b) + b) % b;
}

/*
highp vec3 floatHashVec2ToVec3(in highp vec2 f) {
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);

    highp uint h = 2u; // 2 outputs

    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);

    return vec3(
        uintTo01Float(hashUint(h + fx, MAGIC_NUMBERS[0])),
        uintTo01Float(hashUint(h + fy, MAGIC_NUMBERS[1])),
        uintTo01Float(hashUint(h, MAGIC_NUMBERS[2]))
    );
}
//*/

void vertex() {
	vertex_position = VERTEX;
	motionAngleRad = (weather_direction_angle_degrees + 180.0) * PI / 180.0;
}

void fragment() {
	vec4 color = COLOR;
	ivec2 cellDims = particleSpacing + particleDims * particleScale;
	highp vec2 timeOffset = vec2(cos(motionAngleRad), sin(motionAngleRad)) * TIME * speed;
	
	vec2 posInTime = vertex_position + timeOffset;
	
	vec2 cellPos = vec2(
		floor(floor(posInTime.x) / float(cellDims.x)),
		floor(floor(posInTime.y) / float(cellDims.y))
	);

	highp vec2 randVector = floatHashVec2ToVec2(cellPos);
	
	/* note: doesn't work; causes weird artifacts on the particles as they cross cell boundaries
	float finalAngleRad = motionAngleRad + ((randVector.z - 0.5) * weather_direction_angle_rand_range * PI / 180.0);
	vec2 finalTimeOffset = vec2(cos(finalAngleRad), sin(finalAngleRad)) * TIME * speed;
	//*/

	// mod particleSpacing + 1 so that the pixel right on the right/bottom edge of the cell is kept; otherwise it cycles at that x/y position back to the 0 coordinate
	ivec2 particlePosInCell = ivec2(int(floor(randVector.x * positionRandRange)) % (particleSpacing.x + 1), int(floor(randVector.y * positionRandRange)) % (particleSpacing.y + 1));
	//ivec2 particlePosInCell = ivec2(0 % (particleSpacing.x + 1), 0 % (particleSpacing.y + 1)); // TESTING
	vec2 particlePos = cellPos * vec2(cellDims) + vec2(particlePosInCell);

	/* TESTING
	if (color.a == 0.0) {
		vec2 dist = vec2(float(abs(particlePos.x - posInTime.x)), float(abs(particlePos.y - posInTime.y))) / vec2(cellDims);
		color = vec4(negativeOkModulus(int(floor(cellPos.x)), 2) == 0 ? 1.0 : 0.0, negativeOkModulus(int(floor(cellPos.y)), 2) == 0 ? 1.0 : 0.0, length(dist), 0.5);
		//color = vec4(finalCellPos.x % 2 == 0 ? 1.0 : 0.0, finalCellPos.y % 2 == 0 ? 1.0 : 0.0, 0, 1);
	}
	//*/

	// if this position is within the selected particle's position for this cell: render a particle
	if (
		posInTime.x >= particlePos.x &&
		posInTime.x <= particlePos.x + float(particleDims.x * particleScale) && 
		posInTime.y >= particlePos.y &&
		posInTime.y <= particlePos.y + float(particleDims.y * particleScale)
	) {
		uint particleIdx = uintHashVec2ToFloat(cellPos) % 4u;
		vec2 particleUV = vec2(float(int(posInTime.x - particlePos.x) / particleScale), float(int(posInTime.y - particlePos.y) / particleScale));
		switch (particleIdx) {
			case 0u:
				color = texture(particle1, particleUV);
				break;
			case 1u:
				color = texture(particle2, particleUV);
				break;
			case 2u:
				color = texture(particle3, particleUV);
				break;
			case 3u:
				color = texture(particle4, particleUV);
				break;
		}
	}

	COLOR = color;
}
