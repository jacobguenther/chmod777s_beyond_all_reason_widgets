-- File: html_css_renderer.lua

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

Length = {
	AbsoluteLengthUnit = {
		['px'] = 1,
		['cm'] = 2,
		['mm'] = 3,
		['q']  = 4, -- quater millimeter
		['in'] = 5, -- inch  1in = 6pc
		['pc'] = 6, -- pica  1pc = 12pt
		['pt'] = 7, -- point 1pt = 1in / 72
	},
	RelativeLengthUnit = {
		-- other relative
		['%'] = 1,
		['fr'] = 2,
		-- relative to font size
		['em'] = 3,
		['rem'] = 4,
		-- relative to viewport
		['vh'] = 5,
		['vw'] = 6,
		['vmax'] = 7,
		['vmin'] = 8,
	},
	parse = function(parser)
		local source = parser.source
		local position = source.position

		local number = source:match_number()
		if number == nil then
			return nil
		end

		local ident = source:match_ident()
		if ident == nil then
			ident = source:match('%%')
		end
		local id = Length.AbsoluteLengthUnit[ident]
		if id then
			return Length:new(number, ident)
		end
		id = Length.RelativeLengthUnit[ident]
		if id then
			return Length:new(number, ident)
		end

		source:seek(position)
		return nil
	end,
}
function Length:new(number, unit)
	if number == nil then number = 0 end
	if unit == nil then unit = "px" end

	if not Length.AbsoluteLengthUnit[unit] and not Length.RelativeLengthUnit[unit] then
		Spring.Echo("no length unit named: '"..unit.."'")
		return nil
	end

	local length = {
		valueType = "length",
		value = number,
		unit = unit,
	}

	function length:as_px(context)
		if Length.AbsoluteLengthUnit[length.unit] then
			local unit = length.unit
			local value = length.value
			local new_value
			if unit == "px" then
				new_value = value
			elseif unit == "cm" then
				new_value = value * 96 / 2.54
			elseif unit == "mm" then
				new_value = value * 96 / 2.54 / 10
			elseif unit == "q" then
				new_value = value * 96 / 2.54 / 10 / 4
			elseif unit == "in" then
				new_value = value * 96
			elseif unit == "pc" then
				new_value = value / 6 * 96
			elseif unit == "pt" then
				new_value = value / 72 * 96
			else
				Spring.Echo("Unkown unit: '"..unit.."'")
				return nil
			end
	
			if new_value ~= nil then
				return Length:new(new_value, "px")
			end
		elseif Length.RelativeLengthUnit[length.unit] then
			Spring.Echo('relative unit lengths not supported yet')

			if context == nil then
				Spring.Echo('can not convert relative unit "'..length.unit..'" without context.')
				return nil
			end

			local unit = length.unit
			local value = length.value
			local new_value
			if unit == "%" then
				new_value = context * value / 100
				return Length:new(new_value, "px")
			end
			
			return nil
		end
		Spring.Echo('could not convert: '..length.value..' '..length.unit..' to absolute(px).')
		return nil
	end

	function length:pretty_string()
		return length.value..length.unit
	end

	return length
end

return Length