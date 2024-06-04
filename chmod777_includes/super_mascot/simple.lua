-- File: super_mascot/simple.lua

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

local IMAGE_DIR = 'LuaUI/Widgets/chmod777_includes/images/'

local Quad = VFS.Include('LuaUI/Widgets/chmod777_includes/utilities_GL4.lua')
local LuaShader = VFS.Include('LuaUI/Widgets/Include/LuaShader.lua')

local glTexture = gl.Texture

local SimpleMascot = {}
function SimpleMascot:new()
	local vsSrc = VFS.LoadFile('LuaUI/Widgets/chmod777_includes/shaders/quad.vs.glsl', VFS.RAW)
	local fsSrc = VFS.LoadFile('LuaUI/Widgets/chmod777_includes/shaders/quad.fs.glsl', VFS.RAW)
	local shader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'Shader')
	local shaderCompiled = shader:Initialize()
	if not shaderCompiled then
		Spring.Echo('[super_mascot/simple.lua] Shader: compilation failed')
		return nil
	end

	local quad = Quad:new(-1, -1, 1, 1, true)

	local mascots = {}
	local images = VFS.DirList(IMAGE_DIR, '*.png')
	for i=1, #images do
		local path = images[i]
		local namePlusExtension = ""
		if path:find("\\") then
			-- windows
			namePlusExtension = path:match('[^\\]+$')
		elseif path:find("/") then
			-- linux
			namePlusExtension = path:match('[^/]+$')
		else
			-- image dir is base dir. ??
			namePlusExtension = path
		end
		local name = namePlusExtension:match('[^%.]+')
		local extension = namePlusExtension:match('%.png')
		mascots[name] = path
	end

	local this = {
		shader = shader,
		quad = quad,
		mascots = mascots,
	}

	function this:Draw(name)
		local texture = this.mascots[name]
		this.shader:Activate()
			glTexture(0, texture)
			this.quad:draw()
			glTexture(0, false)
		this.shader:Deactivate()
	end

	function this:Delete()
		if shader ~= nil then shader:Delete() end
		if quad ~= nil then quad:Delete() end
	end

	function this:mascotNames()
		local names = {}
		for name,path in pairs(this.mascots) do
			names[#names+1] = name
		end
		return names
	end

	return this
end

return SimpleMascot
