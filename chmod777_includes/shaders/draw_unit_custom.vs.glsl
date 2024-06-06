#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// File: draw_unit_custom.vs.glsl
// Author: chmod777
// Originally based on a shader by Beherith and Ivand (gfx_drawunitshape_gl4.lua)

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

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec3 aTangent;
layout (location = 3) in vec3 aBitangent;
layout (location = 4) in vec4 aUV;
layout (location = 5) in uvec2 bonesInfo; //boneIDs, boneWeights

#define pieceIndex (bonesInfo.x & 0x000000FFu)

layout (location = 6) in vec4 iWorldPosRot;  // xyz = pos, w = rotation
layout (location = 10) in uvec4 instData;

uniform vec3 uCamEye;       // xyz, w = unused
uniform vec3 uCamTarget;    // xyz, w = unused
uniform vec4 uPerspParams;  // x = near, y = far, z = fovy, w = aspect(unused)

//__ENGINEUNIFORMBUFFERDEFS__

layout(std140, binding=0) buffer MatrixBuffer {
	mat4 mat[];
};

out DataVS {
	vec2 uv;
	vec3 currentTeamColor;

	vec3 camEye;
	vec3 camTarget;

	// vec4 modelPosition;
	// vec3 modelNormal;
	// vec3 modelTangent;
	// vec3 modelBitangent;

	vec4 worldPosition;
	vec3 worldNormal;
	// vec3 worldTangent;
	// vec3 worldBitangent;

	// vec4 viewPosition;
	// vec3 viewNormal;
	// vec3 viewTangent;
	// vec3 viewBitangent;

	// mat3 modelTBN;
	mat3 worldTBN;
	// mat3 viewTBN;
} OUT;


mat4 LookAtTarget(vec3 eye, vec3 target);
mat4 perspective(float near, float far, float fovy);

void main() {
	uint baseIndex = instData.x;

	mat4 baseMatrix = mat[baseIndex];
	baseMatrix = mat4(1.0);
	mat4 pieceMatrix = mat[baseIndex + pieceIndex + 1u];

	float rotation = iWorldPosRot.w;
	mat4 modelRotationMatrix = mat4(rotation3dY(rotation));

	mat4 modelTranslation = mat4(1.0);
	modelTranslation[3] = vec4(iWorldPosRot.xyz, 1.0);

	mat4 modelMat = modelTranslation
		* modelRotationMatrix
		* baseMatrix
		* pieceMatrix;
	mat4 viewMat = LookAtTarget(uCamEye, uCamTarget);
	mat4 projMat = perspective(uPerspParams.x, uPerspParams.y, uPerspParams.z);

	mat3 modelMat3 = mat3(modelMat);
	mat4 modelViewMat = viewMat * modelMat;
	// mat3 modelViewMat3 = mat3(modelViewMat);

	gl_Position = projMat * modelViewMat * vec4(aPosition, 1.0);

	OUT.uv = aUV.xy;

	uint teamIndex = (instData.z & 0x000000FFu); // leftmost ubyte is teamIndex
	OUT.currentTeamColor = teamColor[teamIndex].rgb;

	OUT.camEye = uCamEye;
	OUT.camTarget = uCamTarget;

	// OUT.modelPosition  = vec4(aPosition, 1.0);
	// OUT.modelNormal    = aNormal;
	// OUT.modelTangent   = aTangent;
	// OUT.modelBitangent = aBitangent;

	OUT.worldPosition  = modelMat  * vec4(aPosition, 1.0);
	OUT.worldNormal    = modelMat3 * aNormal;
	// OUT.worldTangent   = modelMat3 * aTangent;
	// OUT.worldBitangent = modelMat3 * aBitangent;

	// OUT.viewPosition  = modelViewMat  * vec4(aPosition, 1.0);
	// OUT.viewNormal    = modelViewMat3 * aNormal;
	// OUT.viewTangent   = modelViewMat3 * aTangent;
	// OUT.viewBitangent = modelViewMat3 * aBitangent;

	// OUT.modelTBN = mat3(OUT.modelTangent, OUT.modelBitangent, OUT.modelNormal);
	// OUT.worldTBN = mat3(OUT.worldTangent, OUT.worldBitangent, OUT.worldNormal);
	// OUT.viewTBN  = mat3(OUT.viewTangent,  OUT.viewBitangent,  OUT.viewNormal);

	// https://learnopengl.com/PBR/Lighting ------------------------------------
		// vec3 T = normalize(OUT.worldTangent);
		// vec3 N = normalize(OUT.worldNormal);
		// // re-orthogonalize T with respect to N
		// T = normalize(T - dot(T, N) * N);
		// // then retrieve perpendicular vector B with the cross product of T and N
		// vec3 B = cross(N, T);
		// OUT.worldTBN = mat3(T, B, N);
	// https://learnopengl.com/PBR/Lighting ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
}


// ShieldSphereColor.frag
mat4 LookAtTarget(vec3 eye, vec3 target) {
	vec3 localUp = vec3(0.0, 1.0, 0.0);

	vec3 zaxis = normalize(eye - target);
	vec3 xaxis = normalize(cross(localUp, zaxis));
	vec3 yaxis = cross(zaxis, xaxis);

	mat4 lookAtMatrix;

	lookAtMatrix[0] = vec4(xaxis.x, yaxis.x, zaxis.x, 0.0);
	lookAtMatrix[1] = vec4(xaxis.y, yaxis.y, zaxis.y, 0.0);
	lookAtMatrix[2] = vec4(xaxis.z, yaxis.z, zaxis.z, 0.0);
	lookAtMatrix[3] = vec4(dot(xaxis, -eye), dot(yaxis, -eye), dot(zaxis, -eye), 1.0);

	return lookAtMatrix;
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