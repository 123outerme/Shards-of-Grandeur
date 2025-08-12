// Magic numbers from 2-round hash constants:
// https://github.com/skeeto/hash-prospector
const uint MAGIC_NUMBERS[7] = uint[7](
    0x21f0aaadu, 0x7feb352du, 0x846ca68bu,
    0xd168aaadu, 0xaf723597u, 0x9e485565u,
    0xef1d6b47u
);

// Fixes -0.0 by nudging it to a tiny positive value
// Avoids hashing -0.0 and +0.0 to different results
// Has no visible effect on output
highp uint fixZero(in highp float f) {
    const float nudge = uintBitsToFloat(0x00800000u);
    return floatBitsToUint(f + nudge);

    // Alternative: exact fix (slower)
    // uint x = floatBitsToUint(f);
    // return (x == 0x80000000u) ? 0u : x;
}

//-------------------------------------------------------------------------
// uint-based hash function (2-round variant)
// Based on: https://github.com/skeeto/hash-prospector
//-------------------------------------------------------------------------
highp uint hashUint(in highp uint h, in highp uint magic) {
    h++; // Avoid hash(0) = 0, performance cost
    h ^= h >> 16u;
    h *= magic;

    // Uncomment to increase mixing at the cost of speed:
    // h ^= h >> 15u;
    // h *= 0xd35a2d97u;
    // h ^= h >> 16u;

    return h;
}

//-------------------------------------------------------------------------
// uint-to-float conversion functions
//-------------------------------------------------------------------------
// Converts a uint to a float in [0, 1) with 23 bits of randomness
highp float uintTo01Float(in highp uint h) {
	return uintBitsToFloat((h >> 9u) | floatBitsToUint(1.0)) - 1.0; // float(h) / float(~0u);
}

// Converts a uint to a float in (-1, 1) using bit tricks
highp float uintToMinus1_1Float(highp uint h) {
    highp float f = uintBitsToFloat((h & 0x807FFFFFu) | floatBitsToUint(1.0));
    return f - sign(f);
}

//-------------------------------------------------------------------------
// Converts a uvec3 to a vec3 in [0, 1) by applying uintTo01Float per channel
vec3 uvec3To01Vec3(uvec3 h) {
    return vec3(
        uintTo01Float(h.x),
        uintTo01Float(h.y),
        uintTo01Float(h.z)
    );
}

//-------------------------------------------------------------------------
// Hashes a vec3 into a uvec3
// Use fixZero() to handle -0.0 edge case
// Change input/output types or initial seed to define other hashes
uvec3 uintHashVec3ToVec3(in highp vec3 f) {
    // Apply fixZero (or use floatBitsToUint if skipping)
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);
    uint fz = fixZero(f.z);

    // Initial seed — use output size to avoid cross-function collisions
    highp uint h = 3u;

    // Collapse inputs into a shared seed
    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);
    h = hashUint(h + fz, MAGIC_NUMBERS[2]);

    // Finalize each output channel
    return uvec3(
        hashUint(h + fx, MAGIC_NUMBERS[0]),
        hashUint(h + fy, MAGIC_NUMBERS[1]),
        hashUint(h + fz, MAGIC_NUMBERS[2])
    );
}

//-------------------------------------------------------------------------
// Other variations for different input/output combinations
uvec4 uintHashVec2ToVec4(in highp vec2 f) {
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);

    highp uint h = 4u; // 4 outputs → seed = 4

    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);

    return uvec4(
        hashUint(h + fx, MAGIC_NUMBERS[0]),
        hashUint(h + fy, MAGIC_NUMBERS[1]),
        hashUint(h, MAGIC_NUMBERS[2]),
        hashUint(h, MAGIC_NUMBERS[3])
    );
}

uint uintHashVec3ToFloat(in highp vec3 f) {
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);
    uint fz = fixZero(f.z);

    highp uint h = 1u; // 1 output → seed = 1

    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);
    h = hashUint(h + fz, MAGIC_NUMBERS[2]);

    // No need to re-add inputs — entropy already mixed
    return hashUint(h, MAGIC_NUMBERS[0]);
}

uint uintHashVec2ToFloat(in highp vec2 f) {
    uint fx = fixZero(f.x);
    uint fy = fixZero(f.y);

    highp uint h = 1u; // 1 output → seed = 1

    h = hashUint(h + fx, MAGIC_NUMBERS[0]);
    h = hashUint(h + fy, MAGIC_NUMBERS[1]);

    // No need to re-add inputs — entropy already mixed
    return hashUint(h, MAGIC_NUMBERS[0]);
}

// Use like: uvec3To01Vec3(uintHashVec3ToVec3(pos));

// ========================================================
//  💡 Customization Tips and RNG Examples
// ========================================================

// --- Input/Output Variants ---
// - vec2 → float: collapse inputs and hash once
// - vec3 → float: same idea, or reuse float hash
// - uint → float: for seeded RNG (no float input needed)
// - vec2 → vec3 or vec3 → vec4: expand mixing and hash calls

// Add more inputs for higher entropy (visually impreceptible, but may make a
// difference when hash is used for simulations)

// --- Discrete Grid Inputs ---
// For grid-aligned positions, round to nearest int:
// uint x = uint(int(floor(f.x + 0.5)));
// Casting directly from float to uint is not correct since it is undefined for
// negatives in GLSL.

// --- RNG Patterns ---
// Use a uint seed (e.g. particle ID, frame counter, loop index) to generate
// random values without using float inputs at all. Just vary the seed per call.

// 1. Offset by constant
// Use a different constant offset for each value.
// Ensures unique outputs from the same base seed.
	// uint id = particle_id;
	// float size  = uintTo01Float(hashUint(id + 1u, MAGIC_NUMBERS[0]));
	// float speed = uintTo01Float(hashUint(id + 2u, MAGIC_NUMBERS[0]));
	// float color = uintTo01Float(hashUint(id + 3u, MAGIC_NUMBERS[0]));

// 2. XOR with constant
// Similar to offset, but scrambles the seed with a large constant.
	// float size  = uintTo01Float(hashUint(id ^ 0xa5a5a5a5u, MAGIC_NUMBERS[0]));
	// float speed = uintTo01Float(hashUint(id ^ 0x5a5a5a5au, MAGIC_NUMBERS[0]));

// 3. Incrementing seed (counter-style RNG)
// Useful when generating multiple values in sequence from the same seed.
// Keep a local copy of the seed and increment it after each use.
	// uint seed = id;
	// float a = uintTo01Float(hashUint(seed++, MAGIC_NUMBERS[0]));
	// float b = uintTo01Float(hashUint(seed++, MAGIC_NUMBERS[0]));
	// float c = uintTo01Float(hashUint(seed++, MAGIC_NUMBERS[0]));

// These are all good, just differences in code maintenance. You don't need to
// change the index of `MAGIC_NUMBERS[0]` — just make sure the seed input is
// different for each value.

// --- Performance Notes ---
// - You can swap in a different 32-bit hash for hashUint()
// - Remove entropy mixing (+fx, +fy, etc.) for more performance
