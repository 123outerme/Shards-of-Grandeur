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
	vec2 timeOffset = vec2(cos(motionAngleRad), sin(motionAngleRad)) * TIME * speed;

	for(float x = 0.0; x < float(particleDims.x * particleScale); x++) {
		for (float y = 0.0; y < float(particleDims.y * particleScale); y++) {
			vec2 pixelPos = vertex_position - vec2(x, y);
			ivec2 cellPos = ivec2(
				int(floor(pixelPos.x + timeOffset.x) / float(cellDims.x)),
				int(floor(pixelPos.y + timeOffset.y) / float(cellDims.y))
			);

			highp vec2 randVector = floatHashVec2ToVec2(vec2(cellPos));

			// note: doesn't work; causes weird artifacts on the particles as they cross cell boundaries
			//float finalAngleRad = motionAngleRad + ((randVec3.z - 0.5) * weather_direction_angle_rand_range * PI / 180.0);
			//vec2 finalTimeOffset = vec2(cos(finalAngleRad), sin(finalAngleRad)) * TIME * speed;
			/* TESTING
			if (color.a == 0.0) {
				//color = vec4(pixelPos + finalTimeOffset - floor(pixelPos + finalTimeOffset), 0, 1);
				/*
				ivec2 finalCellPos = ivec2(
					int((pixelPos.x + finalTimeOffset.x) / float(cellDims.x)),
					int((pixelPos.y + finalTimeOffset.y) / float(cellDims.y))
				);
				//* /
				//color = vec4(randVec3, 1);
				color = vec4(cellPos.x % 2 == 0 ? 1.0 : 0.0, cellPos.y % 2 == 0 ? 1.0 : 0.0, 0, 0.5);
				//color = vec4(finalCellPos.x % 2 == 0 ? 1.0 : 0.0, finalCellPos.y % 2 == 0 ? 1.0 : 0.0, 0, 1);
			}
			//*/

			//*
			if (
				int(floor(pixelPos.x + timeOffset.x) - round(randVector.x * positionRandRange)) % cellDims.x == 0 &&
				int(floor(pixelPos.y + timeOffset.y) - round(randVector.y * positionRandRange)) % cellDims.y == 0
			) {
				uint particleIdx = uintHashVec2ToFloat(vec2(cellPos)) % 4u;
				vec2 particleUV = vec2(floor(x / float(particleScale)), floor(y / float(particleScale)));
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
			//*/
		}
	}

	COLOR = color;
}
