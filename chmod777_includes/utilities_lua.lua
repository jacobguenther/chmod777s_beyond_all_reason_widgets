-- File: utilities_lua.lua

-- https://gist.github.com/tylerneylon/81333721109155b2d244

local function deep_copy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = {}
	s[obj] = res
	for k, v in pairs(obj) do res[deep_copy(k, s)] = deep_copy(v, s) end
	return setmetatable(res, getmetatable(obj))
end

return {
	deep_copy = deep_copy,
}