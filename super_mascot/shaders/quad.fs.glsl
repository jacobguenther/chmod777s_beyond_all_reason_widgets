#version 420

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (binding = 0) uniform sampler2D img;

in DataVS {
	vec2 uv;
} vs_in;

out vec4 fragColor;

void main() {
	fragColor = texture(img, vs_in.uv);
}