-- MIT License
-- 
-- Copyright (c) 2018 Kouhei Sutou <kou@clear-code.com>
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

-- CHANGE LOG
-- (16 May 2024, chmod777)
--  * Replace spaces with tabs
--  * Parse full rulesets

-- RESOURCES
-- * https://www.w3.org/TR/CSS21/grammar.html


local Parser = {}

local Property
local Source
if VFS then
	local luaWidgetDir = 'LuaUI/Widgets/'
	PropertyParser = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/css_property_parser.lua').CSSPropertySelector
	Source = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/modified_luacs/source.lua')
end

local methods = {}

local metatable = {}
function metatable.__index(parser, key)
	return methods[key]
end

-- Specification: https://www.w3.org/TR/selectors-3/
--
-- Grammar:
--
-- selectors_group
--   : selector [ COMMA S* selector ]*
--   ;
--
-- selector
--   : simple_selector_sequence [ combinator simple_selector_sequence ]*
--   ;
--
-- combinator
--   /* combinators can be surrounded by whitespace */
--   : PLUS S* | GREATER S* | TILDE S* | S+
--   ;
--
-- simple_selector_sequence
--   : [ type_selector | universal ]
--     [ HASH | class | attrib | pseudo | negation ]*
--   | [ HASH | class | attrib | pseudo | negation ]+
--   ;
--
-- type_selector
--   : [ namespace_prefix ]? element_name
--   ;
--
-- namespace_prefix
--   : [ IDENT | '*' ]? '|'
--   ;
--
-- element_name
--   : IDENT
--   ;
--
-- universal
--   : [ namespace_prefix ]? '*'
--   ;
--
-- class
--   : '.' IDENT
--   ;
--
-- attrib
--   : '[' S* [ namespace_prefix ]? IDENT S*
--         [ [ PREFIXMATCH |
--             SUFFIXMATCH |
--             SUBSTRINGMATCH |
--             '=' |
--             INCLUDES |
--             DASHMATCH ] S* [ IDENT | STRING ] S*
--         ]? ']'
--   ;
--
-- pseudo
--   /* '::' starts a pseudo-element, ':' a pseudo-class */
--   /* Exceptions: :first-line, :first-letter, :before and :after. */
--   /* Note that pseudo-elements are restricted to one per selector and */
--   /* occur only in the last simple_selector_sequence. */
--   : ':' ':'? [ IDENT | functional_pseudo ]
--   ;
--
-- functional_pseudo
--   : FUNCTION S* expression ')'
--   ;
--
-- expression
--   /* In CSS3, the expressions are identifiers, strings, */
--   /* or of the form "an+b" */
--   : [ [ PLUS | '-' | DIMENSION | NUMBER | STRING | IDENT ] S* ]+
--   ;
--
-- negation
--   : NOT S* negation_arg S* ')'
--   ;
--
-- negation_arg
--   : type_selector | universal | HASH | class | attrib | pseudo
--   ;
--
--
-- Lexer:
--
-- %option case-insensitive
--
-- ident     [-]?{nmstart}{nmchar}*
-- name      {nmchar}+
-- nmstart   [_a-z]|{nonascii}|{escape}
-- nonascii  [^\0-\177]
-- unicode   \\[0-9a-f]{1,6}(\r\n|[ \n\r\t\f])?
-- escape    {unicode}|\\[^\n\r\f0-9a-f]
-- nmchar    [_a-z0-9-]|{nonascii}|{escape}
-- num       [0-9]+|[0-9]*\.[0-9]+
-- string    {string1}|{string2}
-- string1   \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*\"
-- string2   \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*\'
-- invalid   {invalid1}|{invalid2}
-- invalid1  \"([^\n\r\f\\"]|\\{nl}|{nonascii}|{escape})*
-- invalid2  \'([^\n\r\f\\']|\\{nl}|{nonascii}|{escape})*
-- nl        \n|\r\n|\r|\f
-- w         [ \t\r\n\f]*
--
-- D         d|\\0{0,4}(44|64)(\r\n|[ \t\r\n\f])?
-- E         e|\\0{0,4}(45|65)(\r\n|[ \t\r\n\f])?
-- N         n|\\0{0,4}(4e|6e)(\r\n|[ \t\r\n\f])?|\\n
-- O         o|\\0{0,4}(4f|6f)(\r\n|[ \t\r\n\f])?|\\o
-- T         t|\\0{0,4}(54|74)(\r\n|[ \t\r\n\f])?|\\t
-- V         v|\\0{0,4}(58|78)(\r\n|[ \t\r\n\f])?|\\v
--
-- %%
--
-- [ \t\r\n\f]+     return S;
--
-- "~="             return INCLUDES;
-- "|="             return DASHMATCH;
-- "^="             return PREFIXMATCH;
-- "$="             return SUFFIXMATCH;
-- "*="             return SUBSTRINGMATCH;
-- {ident}          return IDENT;
-- {string}         return STRING;
-- {ident}"("       return FUNCTION;
-- {num}            return NUMBER;
-- "#"{name}        return HASH;
-- {w}"+"           return PLUS;
-- {w}">"           return GREATER;
-- {w}","           return COMMA;
-- {w}"~"           return TILDE;
-- ":"{N}{O}{T}"("  return NOT;
-- @{ident}         return ATKEYWORD;
-- {invalid}        return INVALID;
-- {num}%           return PERCENTAGE;
-- {num}{ident}     return DIMENSION;
-- "<!--"           return CDO;
-- "-->"            return CDC;
--
-- \/\*[^*]*\*+([^/*][^*]*\*+)*\/                    /* ignore comments */
--
-- .                return *yytext;

local function on(parser, name, ...)
	local listener = parser.listener
	local callback = listener["on_" .. name]
	-- Spring.Echo("on_" .. name, ...)
	if callback then
		callback(listener, ...)
	end
end

local function type_selector(parser)
	local source = parser.source
	local position = source.position
	local namespace_prefix = source:match_namespace_prefix()
	local element_name = source:match_ident()

	if not element_name then
		source:seek(position)
		return false
	end

	on(parser, "type_selector", namespace_prefix, element_name)
	return true
end

local function universal(parser)
	local source = parser.source
	local position = source.position
	local namespace_prefix = source:match_namespace_prefix()
	local asterisk = source:match("%*")

	if not asterisk then
		source:seek(position)
		return false
	end

	on(parser, "universal", namespace_prefix)
	return true
end

local function hash(parser)
	local name = parser.source:match_hash()
	if name then
		on(parser, "hash", name)
		return true
	else
		return false
	end
end

local function class(parser)
	local source = parser.source
	local position = source.position

	if not source:match("%.") then
		return false
	end

	local name = parser.source:match_ident()
	if name then
		on(parser, "class", name)
		return true
	else
		source:seek(position)
		return false
	end
end

local function attribute(parser)
	local source = parser.source
	local position = source.position

	if not source:match("%[") then
		return false
	end

	source:match_whitespaces()

	local position_name = source.position
	local namespace_prefix = source:match_namespace_prefix()

	local name = parser.source:match_ident()
	if not name then
		source:seek(position_name)
		namespace_prefix = nil
		name = source:match_ident()
		if not name then
			source:seek(position)
			return false
		end
	end

	source:match_whitespaces()

	local operator = nil
	if source:match("%^=") then
		operator = "^="
	elseif source:match("%$=") then
		operator = "$="
	elseif source:match("%*=") then
		operator = "*="
	elseif source:match("=") then
		operator = "="
	elseif source:match("~=") then
		operator = "~="
	elseif source:match("|=") then
		operator = "|="
	end

	local value = nil
	if operator then
		source:match_whitespaces()
		value = source:match_ident()
		if not value then
			value = source:match_string()
		end
		if not value then
			source:seek(position)
			return false
		end
		source:match_whitespaces()
	end

	if not source:match("%]") then
		source:seek(position)
		return false
	end

	on(parser, "attribute", namespace_prefix, name, operator, value)
	return true
end

local function expression_component(parser, expression)
	local source = parser.source

	if source:match("%+") then
		table.insert(expression, {"plus"})
		return true
	end

	if source:match("-") then
		table.insert(expression, {"minus"})
		return true
	end

	local dimension = source:match_dimension()
	if dimension then
		table.insert(expression, {"dimension", dimension})
		return true
	end

	local number = source:match_number()
	if number then
		table.insert(expression, {"number", number})
		return true
	end

	local string = source:match_string()
	if string then
		table.insert(expression, {"string", string})
		return true
	end

	local name = source:match_ident()
	if name then
		table.insert(expression, {"name", name})
		return true
	end

	return false
end

local function functional_pseudo(parser)
	local source = parser.source
	local position = source.position

	local function_name = source:match_ident()
	if not function_name then
		return false
	end

	if not source:match("%(") then
		source:seek(position)
		return false
	end

	local expression = {}
	while true do
		source:match_whitespaces()
		if not expression_component(parser, expression) then
			break
		end
	end

	if #expression == 0 then
		source:seek(position)
		return false
	end

	if source:match("%)") then
		on(parser, "functional_pseudo", function_name, expression)
		return true
	else
		source:seek(position)
		return false
	end
end

local function pseudo(parser)
	local source = parser.source
	local position = source.position

	if not source:match(":") then
		return false
	end

	local event_name
	if source:match(":") then
		event_name = "pseudo_element"
	else
		event_name = "pseudo_class"
	end

	if functional_pseudo(parser) then
		return true
	end

	local name = source:match_ident()
	if name then
		on(parser, event_name, name)
		return true
	else
		source:seek(position)
		return false
	end
end

local function negation(parser)
	local source = parser.source
	local position = source.position

	if not source:match(":not%(") then
		return false
	end

	on(parser, "start_negation")
	source:match_whitespaces()
	if type_selector(parser) or
			 universal(parser) or
			 hash(parser) or
			 class(parser) or
			 attribute(parser) or
			 pseudo(parser) then
		source:match_whitespaces()
		if source:match("%)") then
			on(parser, "end_negation")
			return true
		else
			source:seek(position)
			return false
		end
	else
		source:seek(position)
		return false
	end
end

local function simple_selector_sequence(parser)
	on(parser, "start_simple_selector_sequence")
	local n_required = 1
	if type_selector(parser) or universal(parser) then
		n_required = 0
	end
	local n_occurred = 0
	while hash(parser) or
					class(parser) or
					attribute(parser) or
					negation(parser) or
					pseudo(parser) do
		n_occurred = n_occurred + 1
	end
	local success = (n_occurred >= n_required)
	if success then
		on(parser, "end_simple_selector_sequence")
	end
	return success
end

local function combinator(parser)
	local source = parser.source
	local position = source.position

	local whitespaces = source:match_whitespaces()

	if source:match("%+") then
		source:match_whitespaces()
		on(parser, "combinator", "+")
		return "+"
	elseif source:match(">") then
		source:match_whitespaces()
		on(parser, "combinator", ">")
		return ">"
	elseif source:match("~") then
		source:match_whitespaces()
		on(parser, "combinator", "~")
		return "~"
	elseif whitespaces then
		on(parser, "combinator", " ")
		return " "
	else
		source:seek(position)
		return false
	end
end

local function parse_selector(parser)
	on(parser, "start_selector")
	local source = parser.source
	local position = source.position

	if not simple_selector_sequence(parser) then
		return false
	end

	while true do
		local combinator_current = combinator(parser)
		if not combinator_current then
			break
		end
		if not simple_selector_sequence(parser) then
			if combinator_current == " " then
				break
			end
			return false
		end
	end
	on(parser, "end_selector")
	return true
end

local function parse_selectors_group(parser)
	local source = parser.source
	-- local postition = source.position

	source:match_whitespaces()
	on(parser, "start_selectors_group")
	if not parse_selector(parser) then
		-- error("Failed to parse CSS selectors group: " ..
		-- 	"must have at least one selector: " ..
		-- 	"<" .. parser.source:inspect() .. ">")
		return false
	end
	while true do
		source:match_whitespaces()
		if not source:match(",") then
			break
		end
		source:match_whitespaces()
		if not parse_selector(parser) then
			-- error("Failed to parse CSS selectors group: " ..
			-- 	"must have selector after ',': " ..
			-- 	"<" .. parser.source:inspect() .. ">")
			return false
		end
	end
	source:match_whitespaces()
	if #source.data ~= source.position - 1 then
		-- error("Failed to parse CSS selectors group: " ..
		-- 	"there is garbage after selectors group: " ..
		-- 	"<" .. parser.source:inspect() .. ">")
	end
	on(parser, "end_selectors_group")
	return true
end

function parse_declaration(parser)
	local source = parser.source
	local position = source.position

	local property_name = source:match_ident()
	if not property_name then
		source:seek(position)
		return false
	end

	if not source:match(":") then
		source:seek(position)
		return false
	end
	source:match_whitespaces()

	local property_parser = PropertyParser[property_name]
	if property_parser then
		local value = property_parser(property_name, parser)
		if value then
			source:match_whitespaces()
			if not source:match(";") then
				Spring.Echo("bad ending: did not find ';'")
				return false
			end

			if property_name == 'background-position' then
				value:pretty_print()
			end

			-- unpack certain properties that are shorthands
			if property_name == "padding" then
				local t,r,b,l = "padding-top","padding-right","padding-bottom","padding-left"
				local top,right,bottom,left = unpack(value.value)
				on(parser, "declaration", t, { value = top })
				on(parser, "declaration", r, { value = right })
				on(parser, "declaration", b, { value = bottom })
				on(parser, "declaration", l, { value = left })
			elseif property_name == "border-width" then
				local t,r,b,l = "border-top-width","border-right-width","border-bottom-width","border-left-width"
				local top,right,bottom,left = unpack(value.value)
				on(parser, "declaration", t, { value = top })
				on(parser, "declaration", r, { value = right })
				on(parser, "declaration", b, { value = bottom })
				on(parser, "declaration", l, { value = left })
			elseif property_name == "margin" then
				local t,r,b,l = "margin-top","margin-right","margin-bottom","margin-left"
				local top,right,bottom,left = unpack(value.value)
				on(parser, "declaration", t, { value = top })
				on(parser, "declaration", r, { value = right })
				on(parser, "declaration", b, { value = bottom })
				on(parser, "declaration", l, { value = left })
			else
				on(parser, "declaration", property_name, value)
			end
			return true
		end
	end

	local start_value = source.position
	while not source:match(";") do
		source:seek(source.position+1)
	end

	if source.position-2 <= start_value then
		return false
	end
	local value = source.data:sub(start_value, source.position-2)

	source:match_whitespaces()
	on(parser, "declaration", property_name, value)
	return true
end

function parse_declarations(parser)
	local source = parser.source
	local position = source.position
	if not source:match("{") then
		return false
	end
	source:match_whitespaces()
	while parse_declaration(parser) do
		source:match_whitespaces()
	end
	source:match_whitespaces()
	if not source:match("}") then
		return false
	end
	return true
end

function parse_ruleset(parser)
	on(parser, "start_ruleset")
	if not parse_selectors_group(parser) then
		return false
	end
	if not parse_declarations(parser) then
		return false
	end
	on(parser, "end_ruleset")
	return true
end

function methods:parse()
	on(self, "start_css")
	while parse_ruleset(self) do
		self.source:match_whitespaces()
	end
	on(self, "end_css")
end

function Parser.new(input, listener)
	local parser = {
		source = Source.new(input),
		listener = listener,
	}
	setmetatable(parser, metatable)
	return parser
end

return Parser
