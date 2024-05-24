#version 420
precision highp int;
precision highp float;

// file: classic.vs.glsl
// author: chmod777
// license: GNU AGPL v3

// vertex attributes
layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

// instance attributes
layout (location = 2) in ivec4 instanceFlags;      // see buildInstanceVBOData
layout (location = 3) in vec2 confettiStartPos;
layout (location = 4) in float confettiSpeed;
layout (location = 5) in float confettiRandomSeed;

uniform float imgSize;

uniform vec4 offsets;      // offset.xy, headOffset.xy
uniform vec2 bobRotation;  // x -> bob, y -> rotation
uniform float confettiTime;

const float CONFETTI_SCALE = 0.05;

out DataVS {
	vec2 uv;
	float drawHead;
	float drawHat;
	float isConfetti;
	float confettiPalletIndex;
} vs_out;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

void main() {
	int isConfettiI = instanceFlags.x & 0x10;
	bool isConfetti = bool(isConfettiI);

	vs_out.uv = uv;
	//vs_out.uv.x = 1.0 - uv.x;
	vs_out.uv.y = 1.0 - uv.y;
	vs_out.drawHead = float(instanceFlags.x & 0x04);
	vs_out.drawHat = float(instanceFlags.x & 0x08);
	vs_out.isConfetti = float(isConfettiI);
	vs_out.confettiPalletIndex = float(instanceFlags.y);

	bool useHeadRotation = bool(instanceFlags.x & 0x01);
	bool useHeadOffset = bool(instanceFlags.x & 0x02);

	vec2 offset = offsets.xy;
	vec2 headOffset = offsets.zw;
	float bob = bobRotation.x;
	float rotation = bobRotation.y;

	vec2 imgSize2 = vec2(imgSize);
	
	vec2 coord = coords.xy;
	vec2 translate = vec2(0); //screenPos.xy;

	if (useHeadOffset) {
		translate += headOffset / imgSize;//vec2(0);//fma(headOffset, imgSize2, vec2(0.0, 7));
	}
	if (useHeadRotation) {
		// Center, rotate, then uncenter.
		// Note that the quad has coords 0->1.
		coord = rotate(coords.xy - 0.5, radians(rotation)) + 0.5;

		translate.y += bob / imgSize;
	}


	if (isConfetti) {
		vec2 travel = vec2(confettiTime) * vec2(confettiRandomSeed, confettiSpeed);
		float ground = confettiRandomSeed * 0.1; // so that they don't stack up in a line
		if (travel.y < confettiStartPos.y - ground) {
			translate += confettiStartPos - vec2(sin(travel.x), travel.y);
		} else {
			translate += vec2(confettiStartPos.x, ground);
		}
	}

	// coord = fma(coord, imgSize2, vec2(translate)) / viewGeometry.xy;
	coord = fma(coord, vec2(2.0), vec2(-1.0));
	coord += translate;

	gl_Position = vec4(coord.x, coord.y, 0, 1);
}