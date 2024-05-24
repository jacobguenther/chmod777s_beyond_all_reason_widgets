-- File: css_bg_repeat.lua

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


-- background-repeat =
--   <repeat-style>#

-- <repeat-style> = 
--   repeat-x                                     |
--   repeat-y                                     |
--   [ repeat | space | round | no-repeat ]{1,2}

-- TODO multiple backgrounds seperated by ,
BackgroundRepeatShorthands = {
	['repeat-x'] = 1,
	['repeat-y'] = 2,
}
BackgroundRepeat = {
	['repeat'] = 1,
	['space'] = 2,
	['round'] = 3,
	['no-repeat'] = 4,

	parse = function(name, parser)
		local source = parser.source
	
		local value = source:match_ident_from_table(BackgroundRepeatShorthands)
		if value == 'repeat-x' then
			return {
				valueType = 'background-repeat',
				value = BackgroundRepeat:new('repeat', 'no-repeat'),
			}
		elseif value == 'repeat-y' then
			return {
				valueType = 'background-repeat',
				value = BackgroundRepeat:new('no-repeat', 'repeat'),
			}
		end
	
		value = source:match_ident_from_table(BackgroundRepeat)
		if value == nil then
			return nil
		end
		source:match_whitespaces()
		local value2 = source:match_ident_from_table(BackgroundRepeat)
		if value2 ~= nil then
			value2 = value
		end
		return {
			valueType = 'background-repeat',
			value = BackgroundRepeat:new(value, value2),
		}
	end
}
function BackgroundRepeat:new(repeat_x, repeat_y)
	if repeat_x == nil then repeat_x = 'repeat' end
	if repeat_y == nil then repeat_y = 'repeat' end
	local this = {
		x = repeat_x,
		y = repeat_y,
	}

	return this
end

return BackgroundRepeat
