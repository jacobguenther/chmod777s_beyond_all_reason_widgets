-- File: html_parser.lua

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

local Lexer = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/html_lexer.lua')
local Element = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/element.lua')

local Parser = {}
function Parser:new(source)
	local this = {}
	local lexer = Lexer.Lexer:new(source)
	this.lexemes = {}
	this.lexeme_index = 1
	local lexeme_type,lexeme_source = lexer:next()
	while lexeme_type ~= nil do
		this.lexemes[#this.lexemes+1] = {
			type = lexeme_type,
			source = lexeme_source,
		}
		lexeme_type,lexeme_source = lexer:next()
	end

	function this:current()
		return this.lexemes[this.lexeme_index]
	end
	function this:advance()
		this.lexeme_index = this.lexeme_index + 1
	end
	function this:advance_to_type(type1, type2)
		if type2 == nil then type2 = type1 end

		local start = this.lexeme_index
		local source = ""
		while this.current() ~= nil and this.current().type ~= type1 and this.current().type ~= type2 do
			source = source..this.current().source
			this.advance()
		end
		if this.current() ~= nil and (this.current().type == type1 or this.current().type == type2) then
			return source
		else
			this.lexeme_index = start
			return nil
		end
	end
	function this:skipWhitespaces()
		while this.current() ~= nil and this.current().type == Lexer.LexemeType.WHITESPACE do
			this.advance()
		end
	end

	function this:parse()
		local root = Element.Element:new()
		local element = this.parse_element()
		root.children[#root.children+1] = element
		root:link_elements()
		return root
	end
	function this:parse_element()
		if this.current() == nil then
			return nil
		end
		local start = this.lexeme_index

		this.skipWhitespaces()
		if this.current() ~= nil and this.current().type == Lexer.LexemeType.OPEN then
			this.advance()
		else
			local text = this:advance_to_type(Lexer.LexemeType.OPEN, Lexer.LexemeType.END_OPEN)
			if text ~= nil and text ~= "" then
				-- this.advance()
				return Element.Element:new('text', nil, nil, text)
			end
			this.lexeme_index = start
			return nil
		end
		
		local tag
		if this.current() ~= nil and this.current().type == Lexer.LexemeType.IDENTIFIER then
			tag = this.current().source
			this.advance()
		else
			this.lexeme_index = start
			return nil
		end

		this.skipWhitespaces()
		local attributes = this.parse_attributes()
		
		this.skipWhitespaces()
		if this.current() ~= nil and this.current().type == Lexer.LexemeType.CLOSE then
			this.advance()
		else
			this.lexeme_index = start
			return nil
		end

		-- parse children
		local children = {}
		this.skipWhitespaces()
		local child = this.parse_element()
		while child ~= nil do
			children[#children+1] = child
			this.skipWhitespaces()
			child = this.parse_element()
		end

		this.skipWhitespaces()
		if this.current() ~= nil and this.current().type == Lexer.LexemeType.END_OPEN then
			this.advance()
		else
			this.lexeme_index = start
			return nil
		end

		if this.current() ~= nil and this.current().type == Lexer.LexemeType.IDENTIFIER and this.current().source == tag then
			this.advance()
		else
			this.lexeme_index = start
			return nil
		end

		if this.current() ~= nil and this.current().type == Lexer.LexemeType.CLOSE then
			this.advance()
		else
			this.lexeme_index = start
			return nil
		end

		return Element.Element:new(tag, attributes, children)
	end
	function this:parse_attributes()
		local start = this.lexeme_index
		local attributes = {}
		local key,value = this.parse_attribute()
		while key ~= nil do
			if value == nil then value = true end
			attributes[key] = value
			this.skipWhitespaces()
			key,value = this.parse_attribute()
		end
		return attributes
	end
	function this:parse_attribute()
		local start = this.lexeme_index

		local key = this.pasre_attribute_key()
		if this.current().type == Lexer.LexemeType.EQ then
			this.advance()
		else
			return key
		end
		local value = this.parse_attribute_value()
		return key, value
	end
	function this:pasre_attribute_key()
		local start = this.lexeme_index

		local key
		if this.current().type == Lexer.LexemeType.IDENTIFIER then
			key = this.current().source
			this.advance()
		end

		if key == nil then
			this.lexeme_index = start
			return nil
		else
			return key
		end
	end
	function this:parse_attribute_value()
		local start = this.lexeme_index

		local value
		if this.current().type == Lexer.LexemeType.IDENTIFIER then
			value = this.current().source
			this.advance()
			return value
		elseif this.current().type == Lexer.LexemeType.SINGLE_QUOTE then
			local start_value = this.lexeme_index
			this.advance()
			value = this:advance_to_type(Lexer.LexemeType.SINGLE_QUOTE)
			if value ~= nil then
				this.advance()
				return value
			end
		elseif this.current().type == Lexer.LexemeType.DOUBLE_QUOTE then
			local start_value = this.lexeme_index
			this.advance()
			value = this:advance_to_type(Lexer.LexemeType.DOUBLE_QUOTE)
			if value ~= nil then
				this.advance()
				return value
			end
		end
		
		this.lexeme_index = start
		return nil
	end

	return this
end


return Parser
