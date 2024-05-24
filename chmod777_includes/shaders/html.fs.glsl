#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

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

layout (binding = 0) uniform sampler2D tex0;
layout (binding = 1) uniform sampler2D tex1;
layout (binding = 2) uniform sampler2D tex2;
layout (binding = 3) uniform sampler2D tex3;
layout (binding = 4) uniform sampler2D tex4;
layout (binding = 5) uniform sampler2D tex5;
layout (binding = 6) uniform sampler2D tex6;
layout (binding = 7) uniform sampler2D tex7;

in DataVS {
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
} vs_in;

out vec4 fragColor;

vec4 image_color(int image_flag, vec2 image_uv) {
	vec4 color;
	if (image_flag == 1) { color = texture(tex0, image_uv); }
	if (image_flag == 2) { color = texture(tex1, image_uv); }
	if (image_flag == 3) { color = texture(tex2, image_uv); }
	if (image_flag == 4) { color = texture(tex3, image_uv); }
	if (image_flag == 5) { color = texture(tex4, image_uv); }
	if (image_flag == 6) { color = texture(tex5, image_uv); }
	if (image_flag == 7) { color = texture(tex6, image_uv); }
	if (image_flag == 8) { color = texture(tex7, image_uv); }
	return color;
}
vec4 image_on_top(vec4 base, vec4 image, bool is_active) {
	return mix(base, image, image.a * float(is_active));
}
vec4 image_color_or_one(vec4 color, bool is_active) {
	return fma(color, vec4(float(is_active)), vec4(float(!is_active)));
}

float radius = 5.0;
vec4 border_width = vec4(5.0, 5.0, 5.0, 5.0);
vec4 border_color = vec4(1.0, 0.0, 0.0, 1.0);

void main() {
	vec2 uv = vs_in.uv;
	vec4 flags = vs_in.flags;
	vec4 background_color = vs_in.background_color;
	vec4 background_images = vs_in.background_images;

	ivec3 active_image_flags = ivec3(floor(background_images.xyz + vec3(0.1)));
	int background_blend_mode = int(floor(background_images.w+0.1));

	bool image0_active = bool(active_image_flags[0]);
	bool image1_active = bool(active_image_flags[1]);
	bool image2_active = bool(active_image_flags[2]);
	int active_image_count = int(image0_active) + int(image1_active) + int(image2_active);

	vec4 image0_color = image_color(active_image_flags[0], vs_in.image0_uv);
	vec4 image1_color = image_color(active_image_flags[1], uv);
	vec4 image2_color = image_color(active_image_flags[2], uv);

	vec4 color;
	// background_blend_mode = 1;
	if (background_blend_mode == 0) { // "normal"
		color = background_color;
		color = image_on_top(color, image2_color, image2_active);
		color = image_on_top(color, image1_color, image1_active);
		color = image_on_top(color, image0_color, image0_active);
	}
	if (background_blend_mode == 1) { // "multiply"
		vec4 a = image_color_or_one(image2_color, image2_active);
		vec4 b = image_color_or_one(image1_color, image1_active);
		vec4 c = image_color_or_one(image0_color, image0_active);
		color = a * b * c * background_color;
	}
	if (background_blend_mode == 2) { // "darken"
	}
	if (background_blend_mode == 3) { // "screen"
	}
	if (background_blend_mode == 4) { // "lighten"
	}
	if (background_blend_mode == 5) { // "overlay"
	}
	if (background_blend_mode == 6) { // "color-dodge"
	}
	if (background_blend_mode == 7) { // "color-burn"
	}
	if (background_blend_mode == 8) { // "hard-light"
	}
	if (background_blend_mode == 8) { // "soft-light"
	}
	if (background_blend_mode == 8) { // "difference"
	}
	if (background_blend_mode == 8) { // "exclusion"
	}
	if (background_blend_mode == 8) { // "hue"
	}
	if (background_blend_mode == 8) { // "saturation"
	}
	if (background_blend_mode == 8) { // "color"
	}
	if (background_blend_mode == 8) { // "luminosity"
	}
	if (background_blend_mode == 8) { // "plus-darker"
	}
	if (background_blend_mode == 8) { // "plus-lighter"
	}

	fragColor = clamp(color, vec4(0.0), vec4(1.0));
}