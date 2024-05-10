#version 330

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (binding = 0) uniform sampler2D body;
layout (binding = 1) uniform sampler2D head;
layout (binding = 2) uniform sampler2D hat;

const vec3 CONFETTI_PALLET[5] = {
	vec3(0.6588, 0.3922, 0.9922), // purple
	vec3(0.1608, 0.8039, 1.0),    // blue
	vec3(0.4706, 1.0,    0.2667), // green
	vec3(1.0,    0.4431, 0.5529), // red
	vec3(0.9922, 1.0,    0.4157), // yellow
};
const float CONFETTI_ALPHA = 0.6;

in DataVS {
	vec2 uv;
	float drawHead;
	float drawHat;
	float isConfetti;
	float confettiPalletIndex;
} vs_in;

out vec4 fragColor;

void main() {
	bool drawHeadB = vs_in.drawHead > 0.5;
	bool drawHatB = vs_in.drawHat > 0.5;
	bool isConfettiB = vs_in.isConfetti > 0.5;
	int palletIndex = int(vs_in.confettiPalletIndex);

	vec4 textureSample = texture(body, vs_in.uv);
	if (drawHeadB) {
		textureSample = texture(head, vs_in.uv);
	}
	if (drawHatB) {
		textureSample = texture(hat, vs_in.uv);
	}

	if (isConfettiB) {
		fragColor.xyz = CONFETTI_PALLET[palletIndex];
		fragColor.a = CONFETTI_ALPHA;
	} else {
		if (textureSample.a < 0.5) {
			fragColor = textureSample * vec4(1, 0, 0, 1);
		} else {
			fragColor = textureSample;
		}
	}
}