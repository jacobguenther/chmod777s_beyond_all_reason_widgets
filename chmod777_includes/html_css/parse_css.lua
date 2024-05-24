-- file: parse_css.lua

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

local CSSParser = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/modified_luacs/parser.lua')
local deep_copy = VFS.Include(luaWidgetDir..'chmod777_includes/utilities_lua.lua').deep_copy

local function parse_css(source)
	local listener = {}

	-- stylesheet
	-- : [ CHARSET_SYM STRING ';' ]?
	--   [S|CDO|CDC]* [ import [ CDO S* | CDC S* ]* ]*
	--   [ [ ruleset | media | page ] [ CDO S* | CDC S* ]* ]*
	local css
	-- ruleset
	-- : selector [ ',' S* selector ]*
	--   '{' S* declaration? [ ';' S* declaration? ]* '}' S*
	-- ;
	local ruleset
	-- declarations
	--   : [ IDENT : value ; ]*
	--   ;
	local declarations
	-- selectors_group
	--   : selector [ COMMA S* selector ]*
	--   ;
	local selector_group
	-- selector
	--   : simple_selector_sequence [ combinator simple_selector_sequence ]*
	--   ;
	local selector
	-- simple_selector_sequence
	--   : [ type_selector | universal ]
	--     [ HASH | class | attrib | pseudo | negation ]*
	--   | [ HASH | class | attrib | pseudo | negation ]+
	--   ;
	local simple_selector_sequence

	listener.on_start_css = function(self)
		css = {}
		css.astType = "css"
	end
	listener.on_end_css = function(self)
	end

	listener.on_start_ruleset = function(self)
		ruleset = {
			elements = {},
			add_element = function(this, new_element)
				local elements = this.elements
				-- Don't add duplicates
				for i=1, #elements do
					if elements[i] == new_element then return end
				end
				elements[#elements+1] = new_element
			end,
		}
		ruleset.astType = "ruleset"
	end
	listener.on_end_ruleset = function(self)
		css[#css+1] = deep_copy(ruleset)
	end

	listener.on_declaration = function(self, property, value)
		ruleset[#ruleset+1] = {
			property = property,
			value = value,
		}
	end

	listener.on_start_selectors_group = function(self)
		selector_group = {}
		selector_group.astType = "selectors_group"
	end
	listener.on_end_selectors_group = function(self)
		ruleset.selector_group = deep_copy(selector_group)
	end

	listener.on_start_selector = function(self)
		selector = {}
		selector.astType = "selector"
	end
	listener.on_end_selector = function(self)
		selector_group[#selector_group+1] = deep_copy(selector)
	end
	
	listener.on_start_simple_selector_sequence = function(self)
		simple_selector_sequence = {}
		simple_selector_sequence.astType = "simple selector sequence"
	end
	listener.on_end_simple_selector_sequence = function(self)
		selector[#selector+1] = simple_selector_sequence
	end
	
	listener.on_type_selector = function(self, namespace_prefix, element_name)
		simple_selector_sequence.type = "type selector"
		simple_selector_sequence.namespace_prefix = namespace_prefix
		simple_selector_sequence.name = element_name
	end
	listener.on_universal = function(self, namespace_prefix)
		simple_selector_sequence.type = "universal"
		simple_selector_sequence.namespace_prefix = namespace_prefix
	end
	listener.on_hash = function(self, name)
		simple_selector_sequence.type = "hash"
		simple_selector_sequence.name = name
	end
	listener.on_class = function(self, name)
		simple_selector_sequence.type = "class"
		simple_selector_sequence.name = name
	end
	listener.on_attribute = function(self, namespace_prefix, name, operator, value)
		simple_selector_sequence.type = "attribute"
		simple_selector_sequence.namespace_prefix = namespace_prefix
		simple_selector_sequence.name = name
		simple_selector_sequence.operator = operator
		simple_selector_sequence.value = value
	end
	listener.on_pseudo_element = function(self, name)
	end
	listener.on_pseudo_class = function(self, name)
	end
	listener.on_functional_pseudo = function(self, name, expression)
	end
	listener.on_start_negation = function(self)
	end
	listener.on_end_negation = function(self)
	end
	listener.on_combinator = function(self, combinator)
		if combinator == " " then
			combinator = "SPACE"
		end
		selector[#selector].combinator = combinator
	end
	local parser = CSSParser.new(source, listener)
	parser:parse()

	return css
end

return parse_css