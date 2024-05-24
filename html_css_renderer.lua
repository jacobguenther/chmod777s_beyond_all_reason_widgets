-- File: html_css_renderer.lua

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
		name    = 'html+css renderer',
		desc    = '',
		author  = 'chmod777',
		date    = 'May 2024',
		license = 'GNU AGPL v3',
		layer   = -999,
		enabled = false,
	}
end

local luaWidgetDir = 'LuaUI/Widgets/'

local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

local myIncludesDir = luaWidgetDir..'chmod777_includes/'
local HTMLParser = VFS.Include(myIncludesDir..'html_css/html_parser.lua')
local parse_css = VFS.Include(myIncludesDir..'html_css/parse_css.lua')
local Layout = VFS.Include(myIncludesDir..'html_css/layout.lua')
local Quad,FBO = VFS.Include(myIncludesDir..'utilities_GL4.lua')

local css_source = VFS.LoadFile(myIncludesDir..'ui/main.css', VFS.RAW)
local html_source = VFS.LoadFile(myIncludesDir..'ui/index.html', VFS.RAW)

local vsSrc = VFS.LoadFile(myIncludesDir..'shaders/html.vs.glsl', VFS.RAW)
local fsSrc = VFS.LoadFile(myIncludesDir..'shaders/html.fs.glsl', VFS.RAW)

local InstanceQuad = {}
function InstanceQuad:new(maxElements, maxTexturesPerGroup)
	if maxElements == nil then maxElements = 32 end
	if maxTexturesPerGroup == nil then maxTexturesPerGroup = 8 end

	local this = {}
	this.elementCount = 0
	this.quad = Quad:new(0, 0, 1, 1, true);
	this.textures = {}
	this.textureGroups = {
		{
			textures = {},
			start = 0,
			count = 0,
		}
	}
	this.maxTexturesPerGroup = maxTexturesPerGroup

	local instanceVBOLayout = {
		{id = 2, name = 'flags', size = 4, type = GL.INT},
		{id = 3, name = 'position_size', size = 4, type = GL.FLAOT},
		{id = 4, name = 'background_color', size = 4, type = GL.FLAOT},
		{id = 5, name = 'background_images', size = 4, type = GL.INT},
		{id = 6, name = 'border_widths', size = 4, type = GL.FLAOT},
		{id = 7, name = 'border_color', size = 4, type = GL.FLAOT},
		{id = 8, name = 'image0_size_offset', size = 4, type = GL.FLAOT},
		{id = 9, name = 'image1_size_offset', size = 4, type = GL.FLAOT},
		{id = 10, name = 'image2_size_offset', size = 4, type = GL.FLAOT},
		{id = 11, name = 'image3_size_offset', size = 4, type = GL.FLAOT},
		{id = 12, name = 'image0_origin_repeat_image1_origin_repeat', size = 4, type = GL.INT},
		{id = 13, name = 'image2_origin_repeat_image3_origin_repeat', size = 4, type = GL.INT},
		{id = 14, name = 'image_blend_modes', size = 4, type = GL.INT},
	}
	this.instanceVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	this.instanceVBO:Define(maxElements, instanceVBOLayout)
	this.quad.VAO:AttachInstanceBuffer(this.instanceVBO)

	function this:addQuad(data)
		this.instanceVBO:Upload(
			data,
			-1,                  -- attributeIndex
			this.elementCount,   -- elemOffset
			1,                   -- luaStartIndex
			#data                -- luaFinishIndex
		)
		this.textureGroups[#this.textureGroups].count = this.textureGroups[#this.textureGroups].count + 1
		this.elementCount = this.elementCount+1
		return this.elementCount
	end
	function this:doTexturesFitInCurrentGroup(textures)
		local currentGroup = this.textureGroups[#this.textureGroups]
		local indices = {}
		local found_count = 0
		for n,new_texture in pairs(textures) do
			local found_in_current = false
			for c,current_texture in pairs(currentGroup.textures) do
				if new_texture == current_texture then
					indices[#indices+1] = {n, c}
					Spring.Echo()
					found_in_current = true
					found_count = found_count+1
					break
				end
			end
			if not found_in_current then
				indices[#indices+1] = {n, #currentGroup.textures+n}
			end
		end

		return (#currentGroup.textures + #textures - found_count) <= this.maxTexturesPerGroup, indices
	end
	function this:addTexturedQuad(data, textures)
		local doTheyFit, indices = this:doTexturesFitInCurrentGroup(textures)
		if doTheyFit then
			local currentGroup = this.textureGroups[#this.textureGroups]
			local data_index = 13
			for i=1, #indices do
				local n,c = unpack(indices[i])
				-- Spring.Echo('n', n, textures[n], 'c', c)
				currentGroup.textures[c] = textures[n]
				data[data_index] = c
				data_index = data_index+1
			end
			this:addQuad(data)
		else
			currentGroup = {
				textures = {},
				start = this.elementCount,
				count = 0,
			}
			this.textureGroups[#this.textureGroups+1] = currentGroup
			local data_index = 13
			for i=1, #indices do
				local n,c = unpack(indices[i])
				Spring.Echo('n', n, textures[n], 'c', c)
				currentGroup.textures[i] = textures[i]
				data[data_index] = i
			end
			this:addQuad(data)
		end
	end
	function this:Delete()
		if this.instanceVBO ~= nil then
			this.instanceVBO:Delete()
		end
		if this.quad ~= nil then
			this.quad.Delete()
		end
	end

	return this
end

local stylesheet
local html
local style_tree
local layout_tree

local render_quads
local htmlShader
local viewGeometryUniformLoc

local viewGeometryX,viewGeometryY

local build_render_quads
local add_quad_recursive
local build_shaders

function widget:Initialize()
	stylesheet = parse_css(css_source)
	-- local html_source = '<div/>'
	local html_parser = HTMLParser:new(html_source)

	-- for i=1, #html_parser.lexemes do
	-- 	lexeme = html_parser.lexemes[i]
	-- 	Spring.Echo(lexeme.type, lexeme.source)
	-- end

	document = html_parser.parse()
	style_tree = document:build_style_tree(stylesheet)

	viewGeometryX,viewGeometryY = Spring.GetViewGeometry()
	local size = Layout.Rect:new(0,0,viewGeometryX,viewGeometryY)
	layout_tree = Layout.layout_tree(style_tree, Layout.Dimensions:new(size))

	build_render_quads(layout_tree)

	build_shaders()

	if math.bit_or then
		Spring.Echo('bit_or found')
	else
		Spring.Echo('bit_or not found')
	end
end

function widget:DrawScreen()
	viewGeometryX,viewGeometryY = Spring.GetViewGeometry()
	htmlShader:Activate()
		gl.DepthTest(false)
		for t,group in pairs(render_quads.textureGroups) do
			for i=1, #group.textures do
				gl.Texture(i-1, group.textures[i])
			end
			gl.Uniform(viewGeometryUniformLoc, viewGeometryX, viewGeometryY)
			render_quads.quad.VAO:DrawElements(GL.TRIANGLES, 6, 0, group.count, 0, group.start)
			for i=1, #group.textures do
				gl.Texture(i-1, false)
			end
		end
	htmlShader:Deactivate()
end

build_render_quads = function(layout_tree)
	render_quads = InstanceQuad:new()
	add_quad_recursive(layout_tree)
end
add_quad_recursive = function(layout)
	local content = layout.dimensions.content
	local x,y,w,h = content.x, content.y, content.width, content.height
	y = viewGeometryY-y-h
	

	local blend_mode = layout.style_node:get_value_or('background-blend-mode', 0)

	local background_color = layout.style_node:get_value_or('background-color', Color:new(0,0,0,0,1))
	local r,g,b,a = background_color.r,background_color.g,background_color.b,background_color.a

	local MAX_BACKGROUND_IMAGES = 4
	local background_image_property = layout.style_node:get_declaration('background-image')
	local images = {}
	if background_image_property ~= nil and background_image_property.value ~= nil then
		local image_sources = background_image_property.value
		for i,image_source in ipairs(image_sources) do
			if i >= MAX_BACKGROUND_IMAGES then break end
			images[#images+1] = image_source.value
			local texInfo = gl.TextureInfo(image_source.value)
			local xsize,ysize = texInfo.xsize,texInfo.ysize
			Spring.Echo(image_source.value, xsize, ysize)
		end
	end

	local radius = 16
	-- border widths
	local btop,bright,bleft,bbot = 5,5,5,5
	-- border color
	local br,bg,bb,ba = 1,0,0,1


	local repeat_mode = 1 + 128 -- x: repeat, y: no-repeat

	local data = {
		0,0,0,0,                -- unused flags
		x,y,w,h,                -- position size
		r,g,b,a,                -- background_color
		0,0,0,0,                -- background images indices
		btop,bright,bleft,bbot, -- border widths
		br,bg,bb,ba,            -- border color
		256,256,0,0,            -- image0: size xy, offset xy
		0,0,0,0,                -- image1: size xy, offset xy
		0,0,0,0,                -- image2: size xy, offset xy
		0,0,0,0,                -- image3: size xy, offset xy
		0,repeat_mode,0,0,                -- image0: origin, repeat mode image1 origin, repeat mode
		0,0,0,0,                -- image2: origin, repeat mode image3 origin, repeat mode
		0,0,0,0,                -- image0-3: blendmode0, blendmode1, blendmode2, blendmode3
	}
	if #images > 0 then
		render_quads:addTexturedQuad(data, images)
	else
		render_quads:addQuad(data)
	end

	for i,child in ipairs(layout.children) do
		add_quad_recursive(child)
	end
end

build_shaders = function()
	htmlShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
		uniformFloat = {},
		uniformInt = {},
		textures = {}
	}, 'Quad Shader')
	local htmlShaderCompiled = htmlShader:Initialize()
	if not htmlShaderCompiled then
		Spring.Echo('Quad Shader: compilation failed')
		widgetHandler:RemoveWidget()
	end
	local shader = htmlShader.shaderObj
	viewGeometryUniformLoc = gl.GetUniformLocation(shader, 'viewGeometry')
end