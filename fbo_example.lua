-- File: fbo_example.lua

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

function widget:GetInfo()
	return {
		name    = 'FBO example',
		desc    = 'A minimal FBO example. Requires chmod777_includes/utilites_GL4.lua',
		author  = 'chmod777',
		date    = 'May 2024',
		license = 'GNU AGPL v3',
		layer   = 0,
		enabled = true,
	}
end

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')
local Quad, FBO = VFS.Include(luaWidgetDir..'chmod777_includes/utilities_GL4.lua')

local quadVsSrc = [[
	#version 420

	layout (location = 0) in vec2 coords;
	layout (location = 1) in vec2 uv;
	
	uniform vec2 viewGeometry;
	uniform vec2 screenPos;
	uniform float imgSize;
	
	out DataVS {
		vec2 uv;
	} vs_out;
	
	void main() {
		vs_out.uv = uv;
	
		vec2 coord = coords;
	
		coord = fma(coord, vec2(imgSize*0.5), screenPos) / viewGeometry;
		coord = fma(coord, vec2(2.0), vec2(-1.0));
	
		gl_Position = vec4(coord, 0.0, 1.0);
	}
]]
local quadFsSrc = [[
	#version 420

	#extension GL_ARB_uniform_buffer_object : require
	#extension GL_ARB_shading_language_420pack: require
	
	layout (binding = 0) uniform sampler2D img;
	
	in DataVS {
		vec2 uv;
	} vs_in;
	
	out vec4 fragColor;
	
	void main() {
		fragColor = texture(img, vs_in.uv);
	}
]]

local vsSrc = [[
#version 420

layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

out DataVS {
	vec2 uv;
} vs_out;

void main() {
	vs_out.uv = uv;
	gl_Position = vec4(coords, 0.0, 1.0);
}
]]

local fsSrc = [[
#version 420

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (binding = 0) uniform sampler2D imgTop;
layout (binding = 1) uniform sampler2D imgLeft;
layout (binding = 2) uniform sampler2D imgRight;

const vec2 OFFSET_TOP = vec2(0.0, 0.0);
const vec2 OFFSET_LEFT = vec2(0.4, 0.0);
const vec2 OFFSET_RIGHT = vec2(-0.3, 0.0);

in DataVS {
	vec2 uv;
} vs_in;

out vec4 fragColor;

void main() {
	vec2 uv = vs_in.uv;
	vec4 top = texture(imgTop, uv + OFFSET_TOP);
	vec4 left = texture(imgLeft, uv + OFFSET_LEFT);
	vec4 right = texture(imgRight, uv + OFFSET_RIGHT);

	if (uv.y < 0.5) {
		fragColor = top;
		if (1 - uv.x < uv.y) {
			fragColor = right;
		}
		if (uv.x < uv.y) {
			fragColor = left;
		}
	} else if (uv.x > 0.5) {
		fragColor = right;
	} else {
		fragColor = left;
	}
}
]]

local fbo

local combiningShader
local combiningQuad
local imgSize = 256

local screenQuadShader
local screenQuadUniformLocs = {}
local screenQuad

local glViewport = gl.Viewport
local glClear = gl.Clear
local glTexture = gl.Texture
local glUniform = gl.Uniform
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT

function widget:Initialize()
	combiningShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'Combining Shader')
	local combiningShaderCompiled = combiningShader:Initialize()
	if not combiningShaderCompiled then
		Spring.Echo('Img Shader: compilation failed')
		widgetHandler:RemoveWidget()
	end
	combiningQuad = Quad:new(-1,-1, 1, 1, true)

	screenQuadShader = LuaShader({
		vertex = quadVsSrc,
		fragment = quadFsSrc,
	}, 'Quad Shader')
	local quadShaderCompiled = screenQuadShader:Initialize()
	if not quadShaderCompiled then
		Spring.Echo('Quad Shader: compilation failed')
		widgetHandler:RemoveWidget()
	end

	local shader = screenQuadShader.shaderObj;
	screenQuadUniformLocs['screenPos'] = gl.GetUniformLocation(shader, 'screenPos')
	screenQuadUniformLocs['imgSize'] = gl.GetUniformLocation(shader, 'imgSize')
	screenQuadUniformLocs['viewGeometry'] = gl.GetUniformLocation(shader, 'viewGeometry')

	screenQuad = Quad:new()

	fbo = FBO:new(imgSize, imgSize, false)
end

function widget:Shutdown()
	if fbo ~= nil then fbo:Delete() end

	if screenQuadShader ~= nil then screenQuadShader:Delete() end
	if combineShader ~= nil then combineShader:Delete() end

	if screenQuad ~= nil then screenQuad:Delete() end
	if combiningQuad ~= nil then combiningQuad:Delete() end
end

function DrawCombined()
	combiningShader:Activate()
		glTexture(0, "unitpics/armcom.dds")
		glTexture(1, "unitpics/corcom.dds")
		glTexture(2, "unitpics/armgeo.dds")
		combiningQuad:draw()
		glTexture(0, false)
		glTexture(1, false)
		glTexture(2, false)
	combiningShader:Deactivate()
end

function widget:DrawScreen()
	local viewGeometryX,viewGeometryY = Spring.GetViewGeometry()

	glViewport(0, 0, imgSize, imgSize)
		-- Show preview in bottom of screen
		DrawCombined()

		-- render to a texture(fbo.tex)
		fbo:bind()
			glClear(GL_COLOR_BUFFER_BIT, 0,0,0,0)
			DrawCombined()
		fbo:unbind()
	glViewport(0, 0, viewGeometryX, viewGeometryY)

	-- display the texture on a quad in the center of the screen
	screenQuadShader:Activate()
		glTexture(0, fbo.tex)
		glUniform(screenQuadUniformLocs['imgSize'], imgSize)
		glUniform(screenQuadUniformLocs['screenPos'], viewGeometryX/2, viewGeometryY/2)
		glUniform(screenQuadUniformLocs['viewGeometry'], viewGeometryX, viewGeometryY)
		screenQuad:draw()
		glTexture(0, false)
	screenQuadShader:Deactivate()
end
