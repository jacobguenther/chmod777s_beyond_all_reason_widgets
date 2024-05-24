-- File: element.lua

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

local luaWidgetDir = 'LuaUI/Widgets/'

local Length = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_property_parser.lua').Length

local Initial = {
	['display'] = 'block',
	['box-sizing'] = 'content-box',

	['width'] = 'auto',
	['min-width'] = 'auto',
	['max-width'] = 'none',
	
	['height'] = 'auto',
	['min-height'] = 'auto',
	['max-height'] = 'none',
	
	['padding-top'] = Length:new(0, "px"),
	['padding-right'] = Length:new(0, "px"),
	['padding-bottom'] = Length:new(0, "px"),
	['padding-left'] = Length:new(0, "px"),

	['border-top-width'] = Length:new(0, "px"),
	['border-right-width'] = Length:new(0, "px"),
	['border-bottom-width'] = Length:new(0, "px"),
	['border-left-width'] = Length:new(0, "px"),

	['margin-top'] = Length:new(0, "px"),
	['margin-right'] = Length:new(0, "px"),
	['margin-bottom'] = Length:new(0, "px"),
	['margin-left'] = Length:new(0, "px"),

	-- ['background-color'] = Color['transparent'](),
	-- ['background-image'] = 'none',
	-- ['background-size'] = BackgroundSize:new(),
	-- ['background-position'] = BackgroundPosition:new(),
	-- ['background-repeat'] = BackgroundRepeat:new(),
	-- ['background-blend-mode'] = 'normal',

	['div'] = {},
	['span'] = {
		['display'] = 'inline',
	},
}

local Element = {}
function Element:new(tag, attributes, children, text)
	if tag == nil then tag = 'root' end
	if attributes == nil then attributes = {} end
	if children == nil then children = {} end
	if text ~= nil then text = text:gsub("%s+$", "") end
	local this = {
		tag = tag,
		attributes = attributes,
		children = children,
		text = text,
		rulesets = {},
	}
	function this:link_elements(parent, previous_sibling, next_sibling)
		this.parent = parent
		this.previous_sibling = previous_sibling
		this.next_sibling = next_sibling
		for i,child in ipairs(children) do
			child:link_elements(this, this.children[i-1], this.children[i+1])
		end
	end

	function this:build_style_tree(stylesheet)
		local style_tree = this
		for r,ruleset in ipairs(stylesheet) do
			local selector_group = ruleset.selector_group
			local elements = style_tree:get_elements_by_selector_group(selector_group)
			for e,element in ipairs(elements) do
				element:add_ruleset(ruleset)
				ruleset:add_element(element)
			end
		end
		return style_tree
	end
	function this:add_ruleset(new_ruleset)
		local rulesets = this.rulesets
		for r,ruleset in pairs(rulesets) do
			if new_ruleset == ruleset then return end
		end
		this.rulesets[#this.rulesets+1] = new_ruleset
	end
	function this:get_elements_by_selector_group(selector_group)
		local elements = {}
		for g,selector in ipairs(selector_group) do
			this:elements_by_selector(elements, selector, 1, g)
		end
		for c,child in ipairs(this.children) do
			local child_matches = child:get_elements_by_selector_group(selector_group)
			for i,child_match in ipairs(child_matches) do
				child_match:add_this_to_elements(elements)
			end
		end
		return elements
	end
	function this:elements_by_selector(elements, selector, current_i, group)
		local current_selector = selector[current_i]
		local current_type = current_selector.type

		local current_selector_matches = this:simple_selector_matches(current_selector)
		local next_selector = selector[current_i+1]
		if current_selector_matches and next_selector then
			local combinator = current_selector.combinator
			if combinator == "SPACE" then -- descendant
				for child in ipairs(this.children) do
					Spring.Echo("Descendant combinator not implemented")
				end
			elseif combinator == ">" then -- child
				this:child_by_selector(elements, selector, current_i, group)
			elseif combinator == "+" then -- next-sibling
				this:next_sibling_by_selector(elements, selector, current_i, group)
			elseif combinator == "~" then -- subsequent-sibling
				this:subsequent_siblings_by_selector(elements, selector, current_i, group)
			else
				Spring.Echo("Unknown combinator!")
			end
		elseif current_selector_matches then -- and not next_selector
			this:add_this_to_elements(elements)
		elseif next_selector then -- and not current_selector_matches
		else -- not current_selector_matches and not next_selector
		end
	end
	function this:simple_selector_matches(simple_selector)
		local selector_type = simple_selector.type
		if selector_type == "univeral" then
			return true
		elseif selector_type == "type selector" then
			return this.tag == simple_selector.name
		elseif selector_type == "hash" then
			return this.attributes["id"] == simple_selector.name
		elseif selector_type == "class" then
			return this.attributes["class"] == simple_selector.name
		else
			Spring.Echo("Selector "..selector_type.." not implemented!")
			return false
		end
	end
	function this:add_this_to_elements(elements)
		-- Don't add duplicates
		for i=1, #elements do
			if this == elements[i] then return end
		end
		elements[#elements+1] = this
	end
	function this:child_by_selector(elements, selector, current_i, group)
		local next_selector = selector[current_i+1]
		for c,child in ipairs(this.children) do
			if child:simple_selector_matches(next_selector) then
				child:elements_by_selector(elements, selector, current_i+1, group)
			end
		end
	end
	function this:next_sibling_by_selector(elements, selector, current_i, group)
		local next_selector = selector[current_i+1]
		local next_sibling = this.next_sibling
		while next_sibling ~= nil do
			if next_sibling:simple_selector_matches(next_selector) then
				next_sibling:elements_by_selector(elements, selector, current_i+1, group)
				break
			end
			next_sibling = next_sibling.next_sibling
		end
	end
	function this:subsequent_siblings_by_selector(elements, selector, current_i, group)
		local next_selector = selector[current_i+1]
		local next_sibling = this.next_sibling
		while next_sibling ~= nil do
			if next_sibling:simple_selector_matches(next_selector) then
				next_sibling:elements_by_selector(elements, selector, current_i+1, group)
			end
			next_sibling = next_sibling.next_sibling
		end
	end

	function this:get_declaration(property_name)
		local value
		for r,ruleset in ipairs(this.rulesets) do
			for d,declaration in ipairs(ruleset) do
				if property_name == declaration.property then
					value = declaration.value
				end
			end
		end
		return value
	end
	function this:get_initial(property_name)
		return Initial[this.tag][property_name]
	end

	function this:get_value_or(property_name, default)
		local declaration = this:get_declaration(property_name)
		if declaration == nil then
			return default
		end
		if type(declaration) == "table" then
			return declaration.value
		end
		return declaration
	end
	function this:get_absolute_value_or(property_name, default, context)
		local declaration = this:get_declaration(property_name)
		if declaration == nil then
			return default
		end
		return declaration.value:as_px(context).value
	end

	function this:print(tabs)
		if tabs == nil then tabs = 0 end
		local prefix = ""
		for tab=1, tabs do
			prefix = prefix.."\t"
		end
		Spring.Echo(prefix.."{")
		Spring.Echo(prefix.."tag:", this.tag)
		Spring.Echo(prefix.."text:", this.text)
		Spring.Echo(prefix.."attributes:")
		for k,v in pairs(this.attributes) do
			Spring.Echo("\t"..prefix..k,v)
		end
		Spring.Echo(prefix.."children:")
		for k,v in pairs(this.children) do
			v:print(tabs+1)
		end
		Spring.Echo(prefix.."rules")
		for k,v in pairs(this.rulesets) do
			for k,v in pairs(v) do
				Spring.Echo(k,v.property, v.value)
			end
		end

		Spring.Echo(prefix.."}")
	end

	return this
end

return {
	Initial = Initial,
	Element = Element,
}