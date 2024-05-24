-- File: css_bg_size.lua

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

-- background-size =
--   <bg-size>#

-- <bg-size> = 
--   [ <length-percentage [0,∞]> | auto ]{1,2}  |
--   cover                                      |
--   contain

-- TODO multiple backgrounds seperated by ,
BackgroundSize = {
	['auto'] = 0,
	['cover'] = 1,
	['contain'] = 2,
	parse = function (name, parser)
		local source = parser.source
		local position = source.position
	
		local value = source:match_ident_from_table(BackgroundSize)
		if value ~= nil and value ~= 'auto' then
			return {
				valueType = 'background-size',
				value = value
			}
		end
	
		local width
		if value == 'auto' then
			width = value
		else
			width = Length.parse(parser)
		end
		if width == nil then
			return nil
		end
	
		source:match_whitespaces()
	
		local height = Length.parse(parser)
		if height == nil then
			-- TODO match auto
			height = 'auto'
		end
	
		return {
			valueType = 'background-size',
			value = BackgroundSize:new(width, height)
		}
	end
}
function BackgroundSize:new(width, height)
	if width == nil then width = 'auto' end
	if height == nil then height = 'auto' end

	local this = {
		width = width,
		height = height,
	}

	return this
end

return BackgroundSize