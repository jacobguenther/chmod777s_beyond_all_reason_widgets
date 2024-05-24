-- File: css_property_parser.lua

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

-- RESOURCES
-- * https://www.w3.org/TR/CSS21/grammar.html

local luaWidgetDir = 'LuaUI/Widgets/'
local Angle = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_angle.lua')
local BackgroundPosition = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_bg_position.lua')
local BackgroundRepeat = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_bg_repeat.lua')
local BackgroundSize = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_bg_size.lua')
local Color = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_color.lua')
local Gradiant = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_gradient.lua')
local Length = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_length.lua')

Global = {'inherit', 'initial'}
function parse_global_value(parser)
	local value = parser.source:match_one_of_idents(Global)
	if value then
		return {
			valueType = "global",
			value = value,
		}
	end
	return nil
end


Display = {
	-- Globals
	-- 'inherit',
	'initial',
	-- 'revert',
	-- 'revert-layer',
	-- 'unset',

	-- Precomposed
	'block',
	'inline',
	'inline-block',
	-- 'flex',
	-- 'inline-flex',
	-- 'grid',
	-- 'inline-grid',

	-- Box generation
	'none',
	-- 'contents',
}
function parse_display_value(name, parser)
	local value = parser.source:match_one_of_idents(Display)
	if value then
		return {
			valueType = "display",
			value = value,
		}
	end
	return nil
end

Width = {
	'initial',
	'fit-content',
	'min-content',
	'max-content',
	'auto',
}
function parse_width_value(name, parser)
	local value = parser.source:match_one_of_idents(Width)
	if value then
		return {
			valueType = name,
			value = value,
		}
	end
	value = Length.parse(parser)
	if value then
		return {
			valueType = name,
			value = value,
		}
	end
	return nil
end

Padding = {
	'initial'
}
function parse_padding_helper(parser)
	local value = parse_global_value(parser)
	if value then
		return value
	end
	value = Length.parse(parser)
	if value then
		return value
	end
	return nil
end
function parse_padding_value(name, parser)
	local source = parser.source
	local top = parse_padding_helper(parser)
	source:match_whitespaces()
	local right = parse_padding_helper(parser)
	source:match_whitespaces()
	local bottom = parse_padding_helper(parser)
	source:match_whitespaces()
	local left = parse_padding_helper(parser)

	--  /---\  /--------\
	-- top right bottom left
	--  \__________/

	if not top then
		return nil
	end
	if not right then
		right = top
	end
	if not bottom then
		bottom = top
	end
	if not left then
		left = right
	end
	return {
		valueType = name,
		value = {top, right, bottom, left},
	}
end
function parse_padding_top_value(name, parser)
	local value = parse_padding_helper(parser)
	if value then
		return {
			valueType = name,
			value = value,
		}
	end
	return nil
end



Margin = {
	'initial',
	'auto',
}






BlendMode = {
	['normal'] = 0,
	['multiply'] = 1,
	-- ['screen'] = 2,
	-- ['overlay'] = 3,
	-- ['darken'] = 4,
	-- ['lighten'] = 5,
	-- ['color-dodge'] = 6,
	-- ['color-burn'] = 7,
	-- ['hard-light'] = 8,
	-- ['soft-light'] = 9,
	-- ['difference'] = 10,
	-- ['exclusion'] = 11,
	-- ['hue'] = 12,
	-- ['saturation'] = 13,
	-- ['color'] = 14,
	-- ['luminosity'] = 15,

	-- mix-blend-mode
	-- ['plus-darker'] = 16,
	-- ['plus-lighter'] = 17
}
function parse_background_blend_mode(name, parser)
	local value = parse_global_value(parser)
	if value then
		return value
	end

	local ident,value = parser.source:match_ident_from_table(BlendMode)
	return value
end


function parse_background_color(name, parser)
	local source = parser.source
	local position = source.position

	local value = parse_global_value(parser)
	if value then
		return value
	end

	value = Color.parse_color(parser)
	if value then
		return value
	end

	return nil
end


function parse_image(parser)
	local source = parser.source
	local position = source.position

	-- TODO match_whitespace
	source:match_whitespaces()
	local src = source:match("src")
	local start = source:match('%(')
	local start_quote = source:match('%"')
	local path = source:match('[%a%d%/%_]+%.[%a%d]+')
	local end_quote = source:match('%"')
	local finish = source:match('%)')

	if src ~= nil
		and start ~= nil
		and start_quote ~= nil
		and path ~= nil
		and end_quote ~= nil
		and finish ~= nil
	then
		return {
			valueType = "src",
			value = path,
		}
	end


	source:seek(position)
	return nil
end
function parse_background_image(name, parser)
	local source = parser.source
	local position = source.position

	local value = parse_global_value(parser)
	if value then
		return value
	end

	local images = {}
	local image = parse_image(parser)
	while image do
		images[#images+1] = image
		image = parse_image(parser)
	end

	if #images > 0 then
		return {
			valueType = "images",
			value = images,
		}
	end

	source:seek(position)
	return nil
end


BoxSizing = {
	'initial',
	'content-box',
	'border-box'
}
function parse_box_sizing(name, parser)
	local value = parser.source:match_one_of_idents(BoxSizing)
	if value then
		return {
			valueType = 'box-sizing',
			value = value,
		}
	end

	return nil
end

CSSPropertySelector = {
	['display'] = parse_display_value,

	-- ['float'] = float,

	-- ['text-align'] = text_align,
	-- ['font-family'] = ,
	-- ['font-size'] = ,
	-- ['font-stretch'] = ,
	-- ['font-style'] = ,
	-- ['font-variant'] = ,
	-- ['font-weight'] = ,
	-- ['line-height'] = ,

	-- ['color'] = 

	-- ['position']
	-- ['top']
	-- ['right']
	-- ['bottom']
	-- ['left']

	['box-sizing'] = parse_box_sizing,
	-- ['z-index']
	-- ['blend-mode-mix']

	['width'] = parse_width_value,
	['min-width'] = parse_width_value,
	['max-width'] = parse_width_value,

	['height'] = parse_width_value,
	['min-height'] = parse_width_value,
	['max-height'] = parse_width_value,

	['padding'] = parse_padding_value,
	['padding-top'] = parse_padding_top_value,
	['padding-right'] = parse_padding_top_value,
	['padding-bottom'] = parse_padding_top_value,
	['padding-left'] = parse_padding_top_value,

	['margin'] = parse_padding_value,
	['margin-top'] = parse_padding_top_value,
	['margin-right'] = parse_padding_top_value,
	['margin-bottom'] = parse_padding_top_value,
	['margin-left'] = parse_padding_top_value,

	-- ['border'] = border,
	-- ['border-top'] = border_top,
	-- ['border-right'] = border_right,
	-- ['border-bottom'] = border_bottom,
	-- ['border-left'] = border_left,

	['border-width'] = parse_padding_value,
	['border-top-width'] = parse_padding_top_value,
	['border-right-width'] = parse_padding_top_value,
	['border-bottom-width'] = parse_padding_top_value,
	['border-left-width'] = parse_padding_top_value,

	-- ['border-style'] = border_style,
	-- ['border-top-style'] = border_top_style,
	-- ['border-right-style'] = border_right_style,
	-- ['border-bottom-style'] = border_bottom_style,
	-- ['border-left-style'] = border_left_style,

	-- ['border-color'] = border_color,
	-- ['border-top-color'] = border_top_color,
	-- ['border-right-color'] = border_right_color,
	-- ['border-bottom-color'] = border_bottom_color,
	-- ['border-left-color'] = border_left_color,

	-- ['border-radius'] = border_radius,

	-- ['background'] = background,
	['background-color'] = parse_background_color,
	['background-image'] = parse_background_image,

	['background-size'] = BackgroundSize.parse,
	['background-position'] = BackgroundPosition.parse,
	['background-repeat'] = BackgroundRepeat.parse,

	['background-blend-mode'] = parse_background_blend_mode,

	-- flex and grid
	-- ['gap'] = gap,
	-- ['row-gap'] = row_gap,
	-- ['column-gap'] = column_gap,

	-- flex and grid
	-- ['justify-items'] = justify_items,
	-- ['align-items'] = align_items,
	-- ['place-items'] = place_items,
	-- ['justify-content'] = justify_content,
	-- ['align-content'] = align_content,
	-- ['place-content'] = place_content,

	-- flex and grid item
	-- ['justify-self'] = justify_self,
	-- ['align-self'] = align_self,
	-- ['place-self'] = place_self,

	-- flexbox
	-- ['flex-direction'] = flex_direction,
	-- ['flex-wrap'] = flex_wrap,
	-- ['flex-flow'] = flex_flow,

	-- flex item
	-- ['order'] = order,
	-- ['flex-grow'] = flex_grow,
	-- ['flex-shrink'] = flex_shrink,
	-- ['flex-basis'] = flex_basis,
	-- ['flex'] = flex,

	-- grid
	-- ['grid'] = grid,
	-- ['grid-template-columns'] = grid_template_columns,
	-- ['grid-template-rows'] = grid_template_rows,
	-- ['grid-template-area'] = grid_template_area,

	-- grid item
	-- ['grid-column-start'] = grid_column_start,
	-- ['grid-column-end'] = grid_column_end,
	-- ['grid-column'] = grid_column,
	-- ['grid-row-start'] = grid_row_start
	-- ['grid-row-end'] = grid_row_end
	-- ['grid-row'] = grid_row,
	-- ['grid-area'] = grid_area,
}

module = {
	AngleUnit = AngleUnit,
	Length = Length,
	Color = Color,
	CSSPropertySelector = CSSPropertySelector,
}

return module