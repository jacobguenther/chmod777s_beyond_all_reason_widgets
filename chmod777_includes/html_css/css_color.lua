-- File: css_color.lua

--[[
Copyright (C) 2024 chmod777

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License version 3 as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see <https://www.gnu.org/licenses/>. 
]]


Color = {
	['transparent'] = function() return Color:new(0, 0, 0, 0) end,
	
	['aliceblue'] = function() return Color:new(240, 248, 255) end,
	['antiquewhite'] = function() return Color:new(250, 235, 215) end,
	['aqua'] = function() return Color:new(0, 255, 255) end,
	['aquamarine'] = function() return Color:new(127, 255, 212) end,
	['azure'] = function() return Color:new(240, 255, 255) end,
	['beige'] = function() return Color:new(245, 245, 220) end,
	['bisque'] = function() return Color:new(255, 228, 196) end,
	['black'] = function() return Color:new(0, 0, 0) end,
	['blanchedalmond'] = function() return Color:new(255, 235, 205) end,
	['blue'] = function() return Color:new(0, 0, 255) end,
	['blueviolet'] = function() return Color:new(138, 43, 226) end,
	['brown'] = function() return Color:new(165, 42, 42) end,
	['burlywood'] = function() return Color:new(222, 184, 135) end,
	['cadetblue'] = function() return Color:new(95, 158, 160) end,
	['chartreuse'] = function() return Color:new(127, 255, 0) end,
	['chocolate'] = function() return Color:new(210, 105, 30) end,
	['coral'] = function() return Color:new(255, 127, 80) end,
	['cornflowerblue'] = function() return Color:new(100, 149, 237) end,
	['cornsilk'] = function() return Color:new(255, 248, 220) end,
	['crimson'] = function() return Color:new(220, 20, 60) end,
	['cyan'] = function() return Color:new(0, 255, 255) end,
	['darkblue'] = function() return Color:new(0, 0, 139) end,
	['darkcyan'] = function() return Color:new(0, 139, 139) end,
	['darkgoldenrod'] = function() return Color:new(184, 134, 11) end,
	['darkgray'] = function() return Color:new(169, 169, 169) end,
	['darkgrey'] = function() return Color:new(169, 169, 169) end,
	['darkgreen'] = function() return Color:new(0, 100, 0) end,
	['darkkhaki'] = function() return Color:new(189, 183, 107) end,
	['darkmagenta'] = function() return Color:new(139, 0, 139) end,
	['darkolivegreen'] = function() return Color:new(85, 107, 47) end,
	['darkorange'] = function() return Color:new(255, 140, 0) end,
	['darkorchid'] = function() return Color:new(153, 50, 204) end,
	['darkred'] = function() return Color:new(139, 0, 0) end,
	['darksalmon'] = function() return Color:new(233, 150, 122) end,
	['darkseagreen'] = function() return Color:new(143, 188, 143) end,
	['darkslateblue'] = function() return Color:new(72, 61, 139) end,
	['darkslategray'] = function() return Color:new(47, 79, 79) end,
	['darkslategrey'] = function() return Color:new(47, 79, 79) end,
	['darkturquoise'] = function() return Color:new(0, 206, 209) end,
	['darkviolet'] = function() return Color:new(148, 0, 211) end,
	['deeppink'] = function() return Color:new(255, 20, 147) end,
	['deepskyblue'] = function() return Color:new(0, 191, 255) end,
	['dimgray'] = function() return Color:new(105, 105, 105) end,
	['dimgrey'] = function() return Color:new(105, 105, 105) end,
	['dodgerblue'] = function() return Color:new(30, 144, 255) end,
	['firebrick'] = function() return Color:new(178, 34, 34) end,
	['floralwhite'] = function() return Color:new(255, 250, 240) end,
	['forestgreen'] = function() return Color:new(34, 139, 34) end,
	['fuchsia'] = function() return Color:new(255, 0, 255) end,
	['gainsboro'] = function() return Color:new(220, 220, 220) end,
	['ghostwhite'] = function() return Color:new(248, 248, 255) end,
	['gold'] = function() return Color:new(255, 215, 0) end,
	['goldenrod'] = function() return Color:new(218, 165, 32) end,
	['gray'] = function() return Color:new(128, 128, 128) end,
	['grey'] = function() return Color:new(128, 128, 128) end,
	['green'] = function() return Color:new(0, 128, 0) end,
	['greenyellow'] = function() return Color:new(173, 255, 47) end,
	['honeydew'] = function() return Color:new(240, 255, 240) end,
	['hotpink'] = function() return Color:new(255, 105, 180) end,
	['indianred'] = function() return Color:new(205, 92, 92) end,
	['indigo'] = function() return Color:new(75, 0, 130) end,
	['ivory'] = function() return Color:new(255, 255, 240) end,
	['khaki'] = function() return Color:new(240, 230, 140) end,
	['lavender'] = function() return Color:new(230, 230, 250) end,
	['lavenderblush'] = function() return Color:new(255, 240, 245) end,
	['lawngreen'] = function() return Color:new(124, 252, 0) end,
	['lemonchiffon'] = function() return Color:new(255, 250, 205) end,
	['lightblue'] = function() return Color:new(173, 216, 230) end,
	['lightcoral'] = function() return Color:new(240, 128, 128) end,
	['lightcyan'] = function() return Color:new(224, 255, 255) end,
	['lightgoldenrodyellow'] = function() return Color:new(250, 250, 210) end,
	['lightgray'] = function() return Color:new(211, 211, 211) end,
	['lightgrey'] = function() return Color:new(211, 211, 211) end,
	['lightgreen'] = function() return Color:new(144, 238, 144) end,
	['lightpink'] = function() return Color:new(255, 182, 193) end,
	['lightsalmon'] = function() return Color:new(255, 160, 122) end,
	['lightseagreen'] = function() return Color:new(32, 178, 170) end,
	['lightskyblue'] = function() return Color:new(135, 206, 250) end,
	['lightslategray'] = function() return Color:new(119, 136, 153) end,
	['lightslategrey'] = function() return Color:new(119, 136, 153) end,
	['lightsteelblue'] = function() return Color:new(176, 196, 222) end,
	['lightyellow'] = function() return Color:new(255, 255, 224) end,
	['lime'] = function() return Color:new(0, 255, 0) end,
	['limegreen'] = function() return Color:new(50, 205, 50) end,
	['linen'] = function() return Color:new(250, 240, 230) end,
	['magenta'] = function() return Color:new(255, 0, 255) end,
	['maroon'] = function() return Color:new(128, 0, 0) end,
	['mediumaquamarine'] = function() return Color:new(102, 205, 170) end,
	['mediumblue'] = function() return Color:new(0, 0, 205) end,
	['mediumorchid'] = function() return Color:new(186, 85, 211) end,
	['mediumpurple'] = function() return Color:new(147, 112, 219) end,
	['mediumseagreen'] = function() return Color:new(60, 179, 113) end,
	['mediumslateblue'] = function() return Color:new(123, 104, 238) end,
	['mediumspringgreen'] = function() return Color:new(0, 250, 154) end,
	['mediumturquoise'] = function() return Color:new(72, 209, 204) end,
	['mediumvioletred'] = function() return Color:new(199, 21, 133) end,
	['midnightblue'] = function() return Color:new(25, 25, 112) end,
	['mintcream'] = function() return Color:new(245, 255, 250) end,
	['mistyrose'] = function() return Color:new(255, 228, 225) end,
	['moccasin'] = function() return Color:new(255, 228, 181) end,
	['navajowhite'] = function() return Color:new(255, 222, 173) end,
	['navy'] = function() return Color:new(0, 0, 128) end,
	['oldlace'] = function() return Color:new(253, 245, 230) end,
	['olive'] = function() return Color:new(128, 128, 0) end,
	['olivedrab'] = function() return Color:new(107, 142, 35) end,
	['orange'] = function() return Color:new(255, 165, 0) end,
	['orangered'] = function() return Color:new(255, 69, 0) end,
	['orchid'] = function() return Color:new(218, 112, 214) end,
	['palegoldenrod'] = function() return Color:new(238, 232, 170) end,
	['palegreen'] = function() return Color:new(152, 251, 152) end,
	['paleturquoise'] = function() return Color:new(175, 238, 238) end,
	['palevioletred'] = function() return Color:new(219, 112, 147) end,
	['papayawhip'] = function() return Color:new(255, 239, 213) end,
	['peachpuff'] = function() return Color:new(255, 218, 185) end,
	['peru'] = function() return Color:new(205, 133, 63) end,
	['pink'] = function() return Color:new(255, 192, 203) end,
	['plum'] = function() return Color:new(221, 160, 221) end,
	['powderblue'] = function() return Color:new(176, 224, 230) end,
	['purple'] = function() return Color:new(128, 0, 128) end,
	['rebeccapurple'] = function() return Color:new(102, 51, 153) end,
	['red'] = function() return Color:new(255, 0, 0) end,
	['rosybrown'] = function() return Color:new(188, 143, 143) end,
	['royalblue'] = function() return Color:new(65, 105, 225) end,
	['saddlebrown'] = function() return Color:new(139, 69, 19) end,
	['salmon'] = function() return Color:new(250, 128, 114) end,
	['sandybrown'] = function() return Color:new(244, 164, 96) end,
	['seagreen'] = function() return Color:new(46, 139, 87) end,
	['seashell'] = function() return Color:new(255, 245, 238) end,
	['sienna'] = function() return Color:new(160, 82, 45) end,
	['silver'] = function() return Color:new(192, 192, 192) end,
	['skyblue'] = function() return Color:new(135, 206, 235) end,
	['slateblue'] = function() return Color:new(106, 90, 205) end,
	['slategray'] = function() return Color:new(112, 128, 144) end,
	['slategrey'] = function() return Color:new(112, 128, 144) end,
	['snow'] = function() return Color:new(255, 250, 250) end,
	['springgreen'] = function() return Color:new(0, 255, 127) end,
	['steelblue'] = function() return Color:new(70, 130, 180) end,
	['tan'] = function() return Color:new(210, 180, 140) end,
	['teal'] = function() return Color:new(0, 128, 128) end,
	['thistle'] = function() return Color:new(216, 191, 216) end,
	['tomato'] = function() return Color:new(255, 99, 71) end,
	['turquoise'] = function() return Color:new(64, 224, 208) end,
	['violet'] = function() return Color:new(238, 130, 238) end,
	['wheat'] = function() return Color:new(245, 222, 179) end,
	['white'] = function() return Color:new(255, 255, 255) end,
	['whitesmoke'] = function() return Color:new(245, 245, 245) end,
	['yellow'] = function() return Color:new(255, 255, 0) end,
	['yellowgreen'] = function() return Color:new(154, 205, 50) end,

	parse_color = function(parser)
		local source = parser.source
		local position = source.position

		local ident = source:match_ident()
		if Color[ident] then
			return Color[ident]().remap_range()
		end

		if ident ~= "rgb" and ident ~= "rgba" then
			source:seek(position)
			return nil
		end
	
		local start = source:match("%(")
		source:match_whitespaces()
		local r = source:match_number()
		source:match_whitespaces()
		local g = source:match_number()
		source:match_whitespaces()
		local b = source:match_number()
		source:match_whitespaces()
		if ident == "rgba" then
			local a = source:match_number()
			source:match_whitespaces()
		end
		local finished = source:match("%)")
	
		if start == nil or r == nil or g == nil or b == nil or finished == nil then
			source:seek(position)
			return nil
		end
	
		if ident == "rgba" and a == nil then
			source:seek(position)
			return nil
		end
	
		if a == nil then
			a = 255
		end
	
		local color = Color:new(r, g, b, a, 255)
		return color:remap_range(1)
	end,
}
function Color:new(r, g, b, a, range)
	if r == nil then r = 0 end
	if g == nil then g = 0 end
	if b == nil then b = 0 end
	if a == nil then a = 255 end
	if range == nil then range = 255 end

	local this = {
		valueType = "color",
		range = range,
		value = {
			r = r,
			g = g,
			b = b,
			a = a,
		}
	}

	function this:remap_range(new_range)
		if new_range == nil then new_range = 1 end
		local value = this.value
		local scale = new_range/this.range
		local r = scale * value.r
		local g = scale * value.g
		local b = scale * value.b
		local a = scale * value.a
		return Color:new(r, g, b, a, new_range)
	end

	return this
end

return Color