#version 420

// file: html.vs.glsl

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

// vertex data
layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

// instance data
layout (location = 2) in ivec4 flags;
layout (location = 3) in vec4 position_size;

layout (location = 4) in vec4 background_color;
layout (location = 5) in ivec4 background_images;

layout (location = 6) in vec4 border_widths;
layout (location = 7) in vec4 border_color;

layout (location = 8) in vec4 image0_size_offset;
layout (location = 9) in vec4 image1_size_offset;
layout (location = 10) in vec4 image2_size_offset;
layout (location = 11) in vec4 image3_size_offset;
layout (location = 12) in ivec4 image0_origin_repeat_image1_origin_repeat;
layout (location = 13) in ivec4 image2_origin_repeat_image3_origin_repeat;
layout (location = 14) in ivec4 image_blend_modes;



uniform vec2 viewGeometry;
uniform float uiScale;

out DataVS {
	vec2 uv;
	vec4 flags;
	vec2 position;
	vec2 size;
	vec4 background_color;
	vec4 background_images;
	vec4 border_widths;
	vec4 border_color;
	vec4 image0_size_offset;
	vec2 image0_uv;
} vs_out;

void main() {
	vec2 position = position_size.xy;
	vec2 size = position_size.zw;

	vec2 image0_size = image0_size_offset.xy;
	vec2 image0_offset = image0_size_offset.zw;
	vec2 image0_uv = uv * size / image0_size;

	int image0_repeat_mode = image0_origin_repeat_image1_origin_repeat.y;
	int image0_x_repeat_mode = image0_repeat_mode & 0xff;
	int image0_y_repeat_mode = (image0_repeat_mode >> 4) & 0xff;

	vec2 coord = fma(coords, size, position) / viewGeometry;
	coord = fma(coord, vec2(2.0), vec2(-1.0));

	gl_Position = vec4(coord, 0, 1);


	vs_out.uv = uv;

	vs_out.flags = flags;

	vs_out.position = position_size.xy;
	vs_out.size = position_size.zw;

	vs_out.background_color = background_color;
	vs_out.background_images = background_images;

	vs_out.border_widths = border_widths;
	vs_out.border_color = border_color;

	vs_out.image0_size_offset = image0_size_offset;
	vs_out.image0_uv = image0_uv;
}