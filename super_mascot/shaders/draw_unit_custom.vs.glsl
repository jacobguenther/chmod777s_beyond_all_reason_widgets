#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 10000
//__DEFINES__

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec3 T;
layout (location = 3) in vec3 B;
layout (location = 4) in vec4 uv;
#if (SKINSUPPORT == 0)
	layout (location = 5) in uint pieceIndex;
#else
	layout (location = 5) in uvec2 bonesInfo; //boneIDs, boneWeights
	#define pieceIndex (bonesInfo.x & 0x000000FFu)
#endif

layout (location = 6) in vec4 worldposrot;  // xyz = pos, w = rotation
layout (location = 7) in vec4 camEye;       // xyz, w = unused
layout (location = 8) in vec4 camTarget;    // xyz, w = unused
layout (location = 9) in vec4 perspParams;  // x = near, y = far, z = fovy, w = aspect(unused)
layout (location = 10) in vec4 parameters;  // x = alpha, y = isstatic, zw = unused
layout (location = 11) in uvec4 instData;

mat4 camLookAt(vec3 eye, vec3 right, vec3 up, vec3 dir) {
	mat4 lookAt = mat4(1.0);
	lookAt[0][0] = right.x;
	lookAt[1][0] = right.y;
	lookAt[2][0] = right.z;
	lookAt[0][1] = up.x;
	lookAt[1][1] = up.y;
	lookAt[2][1] = up.z;
	lookAt[0][2] = dir.x;
	lookAt[1][2] = dir.y;
	lookAt[2][2] = dir.z;
	lookAt[3].xyz = -eye;
	return lookAt;
}
mat4 camLookAtTarget(vec3 eye, vec3 target) {
	vec3 localUp = vec3(0.0, 1.0, 0.0);

	vec3 dir = normalize(target - eye);
	vec3 right = normalize(cross(localUp, dir));
	vec3 up = normalize(cross(dir, right));
	
	return camLookAt(eye, right, up, dir);
}
mat4 perspective(float near, float far, float fovy) {
	float half_fov = fovy/2.0;
	float cot = cos(half_fov)/sin(half_fov);
	float f = tan(fovy / 2.0);
	
	float aspect = 1.0;
	float a = (far + near) / (near - far);
	float b = (2 * far * near) / (near - far);

	return mat4(
		vec4(f / aspect, 0, 0, 0),
		vec4(0, f, 0, 0),
		vec4(0, 0, a, -1),
		vec4(0, 0, b, 0)
	);
}
//__ENGINEUNIFORMBUFFERDEFS__
layout(std140, binding = 2) uniform FixedStateMatrices {
	mat4 modelViewMat;
	mat4 projectionMat;
	mat4 textureMat;
	mat4 modelViewProjectionMat;
};
#line 15000
layout(std140, binding=0) buffer MatrixBuffer {
	mat4 mat[];
};

//enum DrawFlags : uint8_t {
//    SO_NODRAW_FLAG = 0, // must be 0
//    SO_OPAQUE_FLAG = 1,
//    SO_ALPHAF_FLAG = 2,
//    SO_REFLEC_FLAG = 4,
//    SO_REFRAC_FLAG = 8,
//    SO_SHADOW_FLAG = 16,
//    SO_FARTEX_FLAG = 32,
//    SO_DRICON_FLAG = 128, //unused so far
//};

out vec2 v_uv;
out vec4 myTeamColor;

void main() {
	uint baseIndex = instData.x;

	float alpha = parameters.x;
	float isStatic = parameters.y;

	// dynamic models have one extra matrix, as their first matrix is their world pos/offset
	mat4 modelMatrix = mat[baseIndex];
	uint isDynamic = 1u;
	if (isStatic > 0.5) {
		isDynamic = 0u;
	}
	mat4 pieceMatrix = mat[baseIndex + pieceIndex + isDynamic];

	vec4 localModelPos = pieceMatrix * vec4(pos, 1.0);

	// Make the rotation matrix around Y and rotate the model
	mat3 rotY = rotation3dY(worldposrot.w);
	localModelPos.xyz = rotY * localModelPos.xyz;

	mat4 worldPosTranslation = mat4(1.0);
	worldPosTranslation[3] = vec4(worldposrot.xyz, 1.0);

	vec4 worldModelPos = worldPosTranslation*localModelPos;

	uint teamIndex = (instData.z & 0x000000FFu);         // leftmost ubyte is teamIndex
	myTeamColor = vec4(teamColor[teamIndex].rgb, alpha); // pass alpha through

	v_uv = uv.xy;

	mat4 customViewMat = camLookAtTarget(camEye.xyz, camTarget.xyz);
	float near = perspParams.x;
	float far = perspParams.y;
	float fovy = perspParams.z;
	mat4 customProj = perspective(near, far, fovy);
	gl_Position = customProj * customViewMat * worldModelPos;
}