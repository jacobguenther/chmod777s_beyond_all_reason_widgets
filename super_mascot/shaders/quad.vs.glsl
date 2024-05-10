#version 420

layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

out DataVS {
	vec2 uv;
} vs_out;

void main() {
	vs_out.uv = uv;
	gl_Position = vec4(coords, 0, 1);
}