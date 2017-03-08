#version 450 core

#define VOXEL_SRC %%
#define POWER_START %%
#define POWER_LEVELS %%

#define CUBE_POWER POWER_START
#define DIVISOR (1 << CUBE_POWER)
#define DIVISOR_INV (1.0 / DIVISOR)


layout (location = 0) out vec3 outPosition;
layout (location = 1) out flat vec3 outMinEdge;
layout (location = 2) out flat vec3 outMaxEdge;
layout (location = 3) out flat uint outOffset;

uniform mat4 matrix;
uniform vec3 cameraPos;

layout (binding = VOXEL_SRC, std430) buffer BufferIn
{
	uint inData[];
};

uvec4 unpack_2_10_10_10(uint data)
{
	return uvec4(
		(data >>  0) & 0x3FF,
		(data >> 10) & 0x3FF,
		(data >> 20) & 0x3FF,
		(data >> 30) & 0x003);
}

void main(void)
{
	uint index = (gl_VertexID / 8) * 2;

	uint inPos =    inData[index];
	uint inOffset = inData[index + 1];

	// Generate coords on the fly.
	uvec3 upos = unpack_2_10_10_10(inPos).xyz;

	// Generate the front lower left corner position.
	vec3 pos = vec3(upos) * DIVISOR_INV;

	// We draw only half a cube and flip the bits in order
	// to draw the other side, this saves 1/8 shader instances
	// and half a the triangles (not counting the extra di)
	uint bits =   (pos.x > cameraPos.x ? 0x01 : 0x00);
	bits = bits | (pos.y > cameraPos.y ? 0x02 : 0x00);
	bits = bits | (pos.z > cameraPos.z ? 0x04 : 0x00);
	bits = gl_VertexID ^ bits;

	outMinEdge = pos;
	outMaxEdge = pos + vec3(1.0) * DIVISOR_INV;
	outOffset = inOffset;

	vec3 offsetPos = vec3(
		 bits       & 0x1,
		(bits >> 1) & 0x1,
		(bits >> 2) & 0x1) * DIVISOR_INV + pos;

	outPosition = offsetPos;
	gl_Position = matrix * vec4(offsetPos, 1.0);
}
