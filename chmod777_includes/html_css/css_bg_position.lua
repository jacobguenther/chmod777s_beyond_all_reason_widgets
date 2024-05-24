-- File: css_bg_position.lua

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

-- background-position =
--   <bg-position>#

-- <bg-position> =
--   [ left | center | right | top | bottom | <length-percentage> ]  |
--   [ left | center | right | <length-percentage> ] [ top | center | bottom | <length-percentage> ]  |
--   [ center | [ left | right ] <length-percentage>? ] && [ center | [ top | bottom ] <length-percentage>? ]

-- TODO multiple backgrounds seperated by ,
BackgroundPosition = {
	['center'] = 0,
	['top'] = 1,
	['bottom'] = 2,
	['left'] = 3,
	['right'] = 4,
	parse = function(name, parser)
		local source = parser.source
		local position = source.position
	
		local origin1 = source:match_ident_from_table(BackgroundPosition)
		source:match_whitespaces()
		local offset1 = Length.parse(parser)
		source:match_whitespaces()
		local origin2 = source:match_ident_from_table(BackgroundPosition)
		source:match_whitespaces()
		local offset2 = Length.parse(parser)
	
		if ((origin1 == 'left' or origin1 =='right') and (origin2 == 'left' or origin2 == 'right'))
			or ((origin1 == 'top' or origin1 == 'bottom') and (origin2 == 'top' or origin2 == 'botom'))
			or (origin1 == 'center' and offset1 ~= nil and origin2 ~= nil) -- center num keyword
			or (origin2 == 'center' and offset2 ~= nil)                    -- keyword num? center num
		then
			return nil
		end
	
		local vertical = 'top'
		local horizontal = 'left'
		local vertical_offset = Length:new(0, 'px')
		local horizontal_offset = Length:new(0, 'px')
	
		if (origin1 == 'center' and origin2 == nil and offset1 == nil)
			or (origin1 == 'center' and origin2 == 'center')
		then
			return BackgroundPosition:new('center', 'center', vertical_offset, horizontal_offset)
		end
	
		if (origin1 == 'top' or origin1 == 'bottom') or (origin2 == 'left' or origin2 == 'right') then
			vertical = origin1
			horizontal = origin2
			vertical_offset = offset1
			horizontal_offset = offset2
			return BackgroundPosition:new(vertical, horizontal, vertical_offset, horizontal_offset)
		end
	
		if (origin1 == 'left' or origin1 == 'right') or (origin2 == 'top' or origin2 == 'bottom') then
			vertical = origin2
			horizontal = origin1
			vertical_offset = offset2
			horizontal_offset = offset1
			return BackgroundPosition:new(vertical, horizontal, vertical_offset, horizontal_offset)
		end
	
		source:seek(position)
		return nil
	end
}
function BackgroundPosition:new(vertical, horizontal, vertical_offset, horizontal_offset)
	if horizontal == nil then
		if vertical == 'center' then
			horizontal = 'center'
		else
			horizontal = 'left'
		end
	end
	if vertical == nil then vertical = 'top' end
	if vertical_offset == nil then vertical_offset = Length:new(0, 'px') end
	if horizontal_offset == nil then horizontal_offset = Length:new(0, 'px') end

	local this = {
		valueType = 'background-position',
		value = {
			origin = {
				vertical = vertical,
				horizontal = horizontal,
			},
			offset = {
				vertical = vertical_offset,
				horizontal = horizontal_offset,
			}
		}
	}

	function this:pretty_string()
		local origin = this.value.origin
		local offset = this.value.offset
		local part1 = origin.vertical.." "..offset.vertical:pretty_string()
		local part2 = origin.horizontal.." "..offset.horizontal:pretty_string()
		return part1..", "..part2
	end
	function this:pretty_print()
		Spring.Echo(this.valueType, this:pretty_string())
	end

	return this
end

return BackgroundPosition