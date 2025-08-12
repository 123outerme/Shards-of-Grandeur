shader_type canvas_item;

// CC0 licensed source: https://github.com/MMqd/uint-shader-hash
#include "res://scripts/shaders/uint_hash.gdshaderinc"

/** Angle (in degrees) at which the weather particles will fall
*/
uniform float weather_direction_angle_degrees = 45.0;

/** The angle range (in degrees) at which `weather_direction_angle_degrees` will randomly vary per particle
*/
uniform float weather_direction_angle_rand_range = 2.0;

/** Speed at which the weather particles will fall
*/
uniform float speed = 10.0;

/** Density in the X direction of the particles on the screen
*/
uniform int horizontalDensity = 4;

/** Density in the Y direction of the particles on the screen
*/
uniform int verticalDensity = 4;

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

uniform float particleScale = 1.0;

varying vec2 vertex_position;
varying float motionAngleRad;

vec3 floatHashVec2ToVec3(in highp vec2 f) {
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

void vertex() {
	vertex_position = VERTEX;
	motionAngleRad = (weather_direction_angle_degrees + 180.0) * PI / 180.0;
	COLOR = vec4(0, 0, 0, 0);
}

void fragment() {
	vec4 color = COLOR;

	for(float x = 0.0; x < float(particleDims.x); x++) {
		for (float y = 0.0; y < float(particleDims.y); y++) {
			vec2 pixelPos = vertex_position - vec2(x, y);
			ivec2 cellDims = ivec2(horizontalDensity + particleDims.x, verticalDensity + particleDims.y);
			vec2 timeOffset = vec2(cos(motionAngleRad), sin(motionAngleRad)) * TIME * speed;
			ivec2 cellPos = ivec2(
				int((pixelPos.x + timeOffset.x) / float(cellDims.x)),
				int((pixelPos.y + timeOffset.y) / float(cellDims.y))
			);
			
			uint particleIdx = uintHashVec2ToFloat(vec2(cellPos)) % 4u;
			
			vec3 randVec3 = floatHashVec2ToVec3(vec2(cellPos));
			float finalAngleRad = motionAngleRad + ((randVec3.z - 0.5) * weather_direction_angle_rand_range * PI / 180.0);
			vec2 finalTimeOffset = vec2(cos(finalAngleRad), sin(finalAngleRad)) * TIME * speed;
			
			if (color.a == 0.0) {
				/*
				ivec2 finalCellPos = ivec2(
					int((pixelPos.x + finalTimeOffset.x) / float(cellDims.x)),
					int((pixelPos.y + finalTimeOffset.y) / float(cellDims.y))
				);
				//*/
				//color = vec4(randVec3, 1);
				//color = vec4(cellPos.x % 2 == 0 ? 1.0 : 0.0, cellPos.y % 2 == 0 ? 1.0 : 0.0, 0, 1);
				//color = vec4(finalCellPos.x % 2 == 0 ? 1.0 : 0.0, finalCellPos.y % 2 == 0 ? 1.0 : 0.0, 0, 1);
			}
			
			//*
			if (
				int(floor(pixelPos.x + timeOffset.x)) % cellDims.x == (int(round(randVec3.x * positionRandRange)) % cellDims.x) && 
				int(floor(pixelPos.y + timeOffset.y)) % cellDims.y == (int(round(randVec3.y * positionRandRange)) % cellDims.y)
			) {
				switch (particleIdx) {
					case 0u:
						color = texture(particle1, vec2(x, y));
						break;
					case 1u:
						color = texture(particle2, vec2(x, y));
						break;
					case 2u:
						color = texture(particle3, vec2(x, y));
						break;
					case 3u:
						color = texture(particle4, vec2(x, y));
						break;
				}
			}
			//*/
		}
	}
	
	COLOR = color;
}
