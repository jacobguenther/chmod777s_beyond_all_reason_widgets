#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// File: draw_unit_custom.fs.glsl
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

// Resources
// https://learnopengl.com/PBR/Lighting
// Recoil Files
//     modelmaterials_gl4/templates/defaultMaterialTemplate.lua


precision highp float;
precision highp int;
precision highp sampler2D;

layout(location = 0) out vec4 color;

// gl.UnitShapeTextures
layout (binding = 0) uniform sampler2D tex0; // albedo
layout (binding = 1) uniform sampler2D tex1; // emission, metalic, roughness

// customparams.normaltex
layout (binding = 3) uniform sampler2D normaltex;


const float PI = 3.14159265359;

const float GAMMA = 2.2;
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);

const mat3 RGB2YCBCR = mat3(
	0.2126, -0.114572, 0.5,
	0.7152, -0.385428, -0.454153,
	0.0722, 0.5, -0.0458471);
const mat3 YCBCR2RGB = mat3(
	1.0, 1.0, 1.0,
	0.0, -0.187324, 1.8556,
	1.5748, -0.468124, -5.55112e-17);

const float BRIGHTNESS_FACTOR = 6.0;

// const float TONEMAP_A = 4.85;
// const float TONEMAP_B = 0.75;
// const float TONEMAP_C = 3.5;
// const float TONEMAP_D = 0.85;
// const float TONEMAP_E = 1.0;
const float ENV_AMBIENT = 0.15;
const float SUN_MULT = 1.0;
const float EXPOSURE_MULT = 1.0;

#define smoothclamp(v, v0, v1) ( mix(v0, v1, smoothstep(v0, v1, v)) )

vec3 getFlatNormal();

// https://learnopengl.com/PBR/Lighting ----------------------------------------
vec3 getNormalFromMap();
float DistributionGGX(vec3 N, vec3 H, float roughness);
float GeometrySchlickGGX(float NdotV, float roughness);
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness);
vec3 fresnelSchlick(float cosTheta, vec3 F0);
// https://learnopengl.com/PBR/Lighting ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


vec3 LINEARtoSRGB(vec3 c) {
	if (GAMMA == 1.0)
		return c;

	float invGamma = 1.0 / GAMMA;
	return pow(c, vec3(invGamma));
}
vec3 SRGBtoLINEAR(vec3 c) {
	if (GAMMA == 1.0)
		return c;

	return pow(c, vec3(GAMMA));
}

//__ENGINEUNIFORMBUFFERDEFS__

in DataVS {
	vec2 uv;
	vec3 currentTeamColor;

	vec3 camEye;
	vec3 camTarget;

	vec3 modelVertPos;
	vec3 worldVertPos;

	mat3 vertTBN;
	vec3 worldNormal;
};

void main() {
	vec4 color0 = texture(tex0, uv.xy);
	vec4 color1 = texture(tex1, uv.xy);

	float teamcolor_mask = color0.a;

	float emission = color1.r;
	float metallic = color1.g;
	float roughness = color1.b;

	vec3 albedo = color0.rgb;
	albedo = mix(albedo, currentTeamColor.rgb, teamcolor_mask);
	albedo = SRGBtoLINEAR(albedo);

	vec3 normalmap = texture(normaltex, uv.xy).rgb;
	normalmap = normalmap * 2.0 - 1.0;
	normalmap = vertTBN * normalmap;
	normalmap = normalize(normalmap);

	vec3 N = normalmap;
	// N = worldNormal;
	// N = getNormalFromMap();
	// N = getFlatNormal();
	vec3 V = normalize(camEye - worldVertPos);

	vec3 F0 = vec3(0.04);

	//   Linear                  Material
	F0 = vec3(0.95, 0.93, 0.88); // silver
	// F0 = vec3(0.91, 0.92, 0.92); // aluminium
	// F0 = vec3(0.56, 0.57, 0.58); // iron

	F0 = mix(F0, albedo, metallic);

	// calculate per-light radiance
	vec3 L = normalize(sunDir.xyz);
	vec3 H = normalize(V + L);
	float NdotL = max(dot(N, L), 0.0);

	float attenuation = 1.0;

	float lightStrength = 1.0;
	vec3 lightColor = sunDiffuseModel.rgb * lightStrength;
	
	vec3 radiance     = lightColor * attenuation;

	// cook-torrance brdf
	float NDF = DistributionGGX(N, H, roughness);
	float G   = GeometrySmith(N, V, L, roughness);
	vec3 F    = fresnelSchlick(max(dot(H, V), 0.0), F0);

	vec3 maxSun = mix(
		sunSpecularModel.rgb,
		sunDiffuseModel.rgb,
		step(
			dot(sunSpecularModel.rgb, LUMA),
			dot(sunDiffuseModel.rgb, LUMA)
		)
	);

	vec3 numerator    = NDF * G * F;
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
	vec3 specular     = numerator / denominator;
	specular *= maxSun;
	specular *= NdotL; // * shadowMult;

	vec3 kS = F;
	vec3 kD = vec3(1.0) - kS;
	kD *= 1.0 - metallic;

	vec3 dirContrib  = maxSun * (kD * albedo /* PI */) * NdotL; // * shadowMult;

	vec3 ambient = mix(vec3(0.0), sunAmbientModel.rgb, ENV_AMBIENT);

	color = vec4(0.0, 0.0, 0.0, 1.0);
	color.rgb = dirContrib * BRIGHTNESS_FACTOR;
	color.rgb += specular;
	color.rgb += albedo*ambient;
	color.rgb += albedo*emission;
	color.rgb *= EXPOSURE_MULT;
	color.rgb = LINEARtoSRGB(color.rgb);

	// TODO animate emission
	// float time = timeInfo.g; // vec4 timeInfo: gameFrame, gameSeconds, drawFrame, frameTimeOffset
	// emission = clamp(emission*sin(time)+0.25, 0.25, 1.0);

	// color.rgb = N;
}


vec3 getFlatNormal()
{
	vec3 Q1  = dFdx(worldVertPos);
	vec3 Q2  = dFdy(worldVertPos);
	return normalize(cross(Q1, Q2));
}

// https://learnopengl.com/PBR/Lighting ----------------------------------------
vec3 getNormalFromMap()
{
	vec3 tangentNormal = texture(normaltex, uv).xyz * 2.0 - 1.0;

	vec3 Q1  = dFdx(worldVertPos);
	vec3 Q2  = dFdy(worldVertPos);
	vec2 st1 = dFdx(uv);
	vec2 st2 = dFdy(uv);

	vec3 N = normalize(worldNormal);
	vec3 T = normalize(Q1*st2.t - Q2*st1.t);
	vec3 B = -normalize(cross(N, T));
	mat3 TBN = mat3(T, B, N);

	return normalize(TBN * tangentNormal);
}
float DistributionGGX(vec3 N, vec3 H, float roughness)
{
	float a      = roughness*roughness;
	float a2     = a*a;
	float NdotH  = max(dot(N, H), 0.0);
	float NdotH2 = NdotH*NdotH;

	float num   = a2;
	float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	denom = PI * denom * denom;

	return num / denom;
}
float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = (roughness + 1.0);
	float k = (r*r) / 8.0;

	float num   = NdotV;
	float denom = NdotV * (1.0 - k) + k;

	return num / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2  = GeometrySchlickGGX(NdotV, roughness);
	float ggx1  = GeometrySchlickGGX(NdotL, roughness);

	return ggx1 * ggx2;
}
vec3 fresnelSchlick(float cosTheta, vec3 F0)
{
	return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}