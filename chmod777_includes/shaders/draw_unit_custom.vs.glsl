#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// File: draw_unit_custom.vs.glsl
// Author: chmod777
// Based on a shader by Beherith and Ivand

/*
Copyright (C) 2024 chmod777

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License version 3 as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>. 
*/

layout (location = 0) in vec3 pos;
layout (location = 1) in vec3 normal;
layout (location = 2) in vec3 T;
layout (location = 3) in vec3 B;
layout (location = 4) in vec4 uv;
layout (location = 5) in uvec2 bonesInfo; //boneIDs, boneWeights

#define pieceIndex (bonesInfo.x & 0x000000FFu)

layout (location = 6) in vec4 worldposrot;  // xyz = pos, w = rotation
layout (location = 7) in vec4 camEye;       // xyz, w = unused
layout (location = 8) in vec4 camTarget;    // xyz, w = unused
layout (location = 9) in vec4 perspParams;  // x = near, y = far, z = fovy, w = aspect(unused)
layout (location = 10) in uvec4 instData;

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

layout(std140, binding=0) buffer MatrixBuffer {
	mat4 mat[];
};

out vec2 v_uv;
out vec4 myTeamColor;

void main() {
	uint baseIndex = instData.x;

	mat4 pieceMatrix = mat[baseIndex + pieceIndex + 1u];
	
	float rotation = worldposrot.w;
	mat4 localRotationMatrix = mat4(rotation3dY(rotation));

	mat4 worldTranslation = mat4(1.0);
	vec4 worldPos = vec4(worldposrot.xyz, 1.0);
	worldTranslation[3] = worldPos;

	vec4 worldModelPos = worldTranslation
		* localRotationMatrix
		* pieceMatrix
		* vec4(pos, 1.0);

	uint teamIndex = (instData.z & 0x000000FFu); // leftmost ubyte is teamIndex
	myTeamColor = teamColor[teamIndex];

	v_uv = uv.xy;

	mat4 customViewMat = camLookAtTarget(camEye.xyz, camTarget.xyz);
	float near = perspParams.x;
	float far = perspParams.y;
	float fovy = perspParams.z;
	mat4 customProj = perspective(near, far, fovy);
	gl_Position = customProj * customViewMat * worldModelPos;
}