-- File: css_gradient.lua

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


-- <gradient> =
--   <linear-gradient()>            |
--   <repeating-linear-gradient()>  |
--   <radial-gradient()>            |
--   <repeating-radial-gradient()>  
--
-- <linear-gradient()> = 
--   linear-gradient( [ <linear-gradient-syntax> ] )  
--
-- <repeating-linear-gradient()> = 
--   repeating-linear-gradient( [ <linear-gradient-syntax> ] )  
--
-- <radial-gradient()> = 
--   radial-gradient( [ <radial-gradient-syntax> ] )  
--
-- <repeating-radial-gradient()> = 
--   repeating-radial-gradient( [ <radial-gradient-syntax> ] )  
--
-- <linear-gradient-syntax> = 
--   [ <angle> | to <side-or-corner> ]? , <color-stop-list>  
--
-- <radial-gradient-syntax> = 
--   [ <radial-shape> || <radial-size> ]? [ at <position> ]? , <color-stop-list>  
--
-- <side-or-corner> = 
--   [ left | right ]  ||
--   [ top | bottom ]  
--
-- <color-stop-list> = 
--   <linear-color-stop> , [ <linear-color-hint>? , <linear-color-stop> ]#  
--
-- <radial-shape> = 
--   circle   |
--   ellipse  
--
-- <radial-size> = 
--   <radial-extent>               |
--   <length [0,∞]>                |
--   <length-percentage [0,∞]>{2}  
--
-- <position> = 
--   [ left | center | right | top | bottom | <length-percentage> ]  |
--   [ left | center | right ] && [ top | center | bottom ]  |
--   [ left | center | right | <length-percentage> ] [ top | center | bottom | <length-percentage> ]  |
--   [ [ left | right ] <length-percentage> ] && [ [ top | bottom ] <length-percentage> ]  
--
-- <linear-color-stop> = 
--   <color> <length-percentage>?  
--
-- <linear-color-hint> = 
--   <length-percentage>  
--
-- <radial-extent> = 
--   closest-corner   |
--   closest-side     |
--   farthest-corner  |
--   farthest-side    
--
-- <length-percentage> = 
--   <length>      |
--   <percentage>  

Gradiant = {
	-- ['linear-gradient'] = 1,
	-- -- ['repeating-linear-gradient'] = 2,
	-- ['radial-gradient'] = 3,
	-- -- ['repeating-radial-gradient'] = 4,
	-- -- ['conic-gradient'] = 5,

	-- parse_gradient = function(name, parser)
	-- 	local source = parser.source
	-- 	local position = source.position
		
	-- 	local ident = match_ident_from_table(parser, Gradiant)
	-- 	if ident == nil then
	-- 		source:seek(position)
	-- 		return nil
	-- 	end

	-- 	local start = source:match('%(')
	-- 	local finish = source:match('%)')
	-- end
}
-- Gradiant:new(angle, colors)

return Gradiant