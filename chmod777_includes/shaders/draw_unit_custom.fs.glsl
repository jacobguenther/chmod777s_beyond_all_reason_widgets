#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// file: draw_unit_custom.fs.glsl
// author: chmod777
// license: GNU AGPL v3

layout(location = 0) out vec4 color;

uniform sampler2D tex1;
uniform sampler2D tex2;

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

in vec2 v_uv;
in vec4 myTeamColor;

void main() {
	vec4 modelColor = texture(tex1, v_uv.xy);
	vec4 extraColor = texture(tex2, v_uv.xy);
	modelColor.rgb += modelColor.rgb * extraColor.r;                     // emission
	modelColor.a *= extraColor.a;                                        // basic model transparency
	modelColor.rgb = mix(modelColor.rgb, myTeamColor.rgb, modelColor.a); // apply teamcolor
	modelColor.a *= myTeamColor.a;                                       // shader define transparency

	color = vec4(modelColor.rgb, 1.0);
}