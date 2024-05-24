-- File: html_lexer.lua

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

LexemeType = {
	OPEN = 1,         -- "<"
	CLOSE = 2,        -- ">"
	END_OPEN = 3,     -- "</"
	SELF_CLOSING = 4, -- "/>"
	EQ = 5,           -- "="
	SINGLE_QUOTE = 6, --  '
	DOUBLE_QUOTE = 7, --  "
	WHITESPACE = 8,   -- \t\n\b
	IDENTIFIER = 9,   -- tag
}

local Lexer = {}
function Lexer:new(source)
	local this = {}
	this.source = source
	this.index = 1
	
	function is_whitespace(c)
		return c == ' ' or c == '\n' or c == '\t' or c == '\r' or c == '\b'
	end
	function is_special(c)
		return c=='<' or c=='>' or c=='/' or c=='=' or c=='"' or c=="'"
	end
	function is_digit(c)
		return c=='0' or c=='1' or c=='2' or c=='3' or c=='4' or c=='5' or c=='6' or c=='7' or c=='8' or c=='9'
	end

	function this:next()
		local current = this:current_char()
		if current == nil then
			return nil
		end

		local start = this.index

		if current == '<' then
			this:advance()
			local next = this:current_char()
			if next == '/' then
				local source = this.source:sub(start, this.index)
				this:advance()
				return LexemeType.END_OPEN, source
			else
				return LexemeType.OPEN, current
			end
		elseif current == '/' and this:next_char() ~= nil and this:next_char() == '>' then
			this:advance()
			this:advance()
			return LexemeType.SELF_CLOSING, this.source:sub(start, this.index)
		elseif current == '>' then
			this:advance()
			return LexemeType.CLOSE, current
		elseif current == '=' then
			this:advance()
			return LexemeType.EQ, current
		elseif current == "'" then
			this:advance()
			return LexemeType.SINGLE_QUOTE, current
		elseif current == '"' then
			this:advance()
			return LexemeType.DOUBLE_QUOTE, current
		elseif is_whitespace(current) then
			while this:next_char() ~= nil and is_whitespace(this:next_char()) do
				this:advance()
			end
			local source = this.source:sub(start, this.index)
			this:advance()
			return LexemeType.WHITESPACE, source
		else
			while this:next_char() ~= nil and not is_special(this:next_char()) and not is_whitespace(this:next_char()) do
				this:advance()
			end
			local source = this.source:sub(start, this.index)
			this:advance()
			return LexemeType.IDENTIFIER, source
		end
	end
	function this:advance()
		this.index = this.index+1
	end
	function this:current_char()
		if this.index > #this.source then
			return nil
		end
		return this.source:sub(this.index, this.index)
	end
	function this:next_char()
		return this.source:sub(this.index+1, this.index+1)
	end

	return this
end

module = {
	LexemeType = LexemeType,
	Lexer = Lexer,
}

return module