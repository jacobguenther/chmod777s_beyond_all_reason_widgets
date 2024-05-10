#version 420

layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

uniform vec2 viewGeometry;
uniform vec2 screenPos;
uniform vec2 imgSize;

out DataVS {
	vec2 uv;
} vs_out;

void main() {
	vs_out.uv = uv;
	vec2 coord = fma(coords, imgSize, screenPos) / viewGeometry;
	coord = fma(coord, vec2(2.0), vec2(-1.0));
	gl_Position = vec4(coord, 0, 1);
}