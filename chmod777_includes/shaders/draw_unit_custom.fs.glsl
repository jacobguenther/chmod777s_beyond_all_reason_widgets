#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// File: draw_unit_custom.fs.glsl
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

layout(location = 0) out vec4 color;

uniform sampler2D tex1;
uniform sampler2D tex2;

//__ENGINEUNIFORMBUFFERDEFS__

in vec2 v_uv;
in vec4 myTeamColor;

void main() {
	vec4 modelColor = texture(tex1, v_uv.xy);
	vec4 extraColor = texture(tex2, v_uv.xy);
	modelColor.rgb += modelColor.rgb * extraColor.r;
	modelColor.a *= extraColor.a;
	modelColor.rgb = mix(modelColor.rgb, myTeamColor.rgb, modelColor.a); // apply teamcolor

	color = vec4(modelColor.rgb, 1.0);
}