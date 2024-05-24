-- File: blobs.lua

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

-- TODO
--  * Move TableConcat to utilities_lua.lua

--------------------------------------------------------------------------------
--  includes
--------------------------------------------------------------------------------

local Quad, FBO = VFS.Include('LuaUI/Widgets/chmod777_includes/utilities_GL4.lua')
local LuaShader = VFS.Include('LuaUI/Widgets/Include/LuaShader.lua')

--------------------------------------------------------------------------------
--  config
--------------------------------------------------------------------------------

local SPHERE_COUNT = 8
local WIDTH = 128
local HEIGHT = 128
local MAX_STEPS = 32
local MAX_DISTANCE = 100.0
local MIN_DISTANCE = 0.001
local SMOOTHING_FACTOR = 0.5
local TIMESCALE = 0.5
local MOVESCALE = 2.0

-- Resources
-- https://iquilezles.org/articles/palettes/
local PALLETS = {
	{
		0.8, 0.5, 0.4, 1.0,
		0.2, 0.4, 0.2, 1.0,
		2.0, 1.0, 1.0, 1.0,
		0.00, 0.25, 0.25, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		1.0, 1.0, 1.0, 1.0,
		0.00, 0.10, 0.20, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		1.0, 1.0, 1.0, 1.0,
		0.30, 0.20, 0.20, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		1.0, 1.0, 0.5, 1.0,
		0.80, 0.90, 0.30, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		1.0, 0.7, 0.4, 1.0,
		0.00, 0.15, 0.20, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		2.0, 1.0, 0.0, 1.0,
		0.50, 0.20, 0.25, 1.0,
	},
	{
		0.5, 0.5, 0.5, 1.0,
		0.5, 0.5, 0.5, 1.0,
		1.0, 1.0, 1.0, 1.0,
		0.00, 0.33, 0.67, 1.0,
	}
}

--------------------------------------------------------------------------------
--  speedups?
--------------------------------------------------------------------------------

local glUseShader = gl.UseShader
local glBindImageTexture = gl.BindImageTexture
local glTexture = gl.Texture
local glUniform = gl.Uniform
local glDispatchCompute = gl.DispatchCompute
local glBlending = gl.Blending

local GL_ARRAY_BUFFER = GL.ARRAY_BUFFER
local GL_NEAREST = GL.NEAREST
local GL_CLAMP_TO_EDGE = GL.CLAMP_TO_EDGE
local GL_READ_WRITE = GL.READ_WRITE
local GL_SHADER_STORAGE_BUFFER = GL.SHADER_STORAGE_BUFFER
local GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = GL.SHADER_IMAGE_ACCESS_BARRIER_BIT
local GL_ALL_BARRIER_BITS = GL.ALL_BARRIER_BITS
local GL_SRC_ALPHA = GL.SRC_ALPHA
local GL_ONE = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA

-- DO NOT TOUCH --
local GL_RGBAF32 = 34836

local function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end

local BlobsMascot = {}
function BlobsMascot:new()
	local computeSource = VFS.LoadFile('LuaUI/Widgets/chmod777_includes/shaders/ray_march.glsl', VFS.RAW)
	local computeShader = gl.CreateShader({
		defines = {
			'#version 430\n',
			'#extension GL_ARB_compute_shader: require\n',
			'#extension GL_ARB_uniform_buffer_object : require\n',
			'#extension GL_ARB_shader_storage_buffer_object : require\n',
			'#define SPHERE_COUNT '..SPHERE_COUNT..'\n',
			'#define WIDTH '..WIDTH..'\n',
			'#define HEIGHT '..HEIGHT..'\n',
			'#define MAX_STEPS '..MAX_STEPS..'\n',
			'#define MAX_DISTANCE '..MAX_DISTANCE..'\n',
			'#define MIN_DISTANCE '..MIN_DISTANCE..'\n',
			'#define SMOOTHING_FACTOR '..SMOOTHING_FACTOR..'\n',
			'#define TIMESCALE '..TIMESCALE..'\n',
			'#define MOVESCALE '..MOVESCALE..'\n',
		},
		definitions = {},
		compute = computeSource,
	})
	local timeUniformLoc = gl.GetUniformLocation(computeShader, 'time');

	local vsSrc = VFS.LoadFile('LuaUI/Widgets/chmod777_includes/shaders/quad.vs.glsl', VFS.RAW)
	local fsSrc = VFS.LoadFile('LuaUI/Widgets/chmod777_includes/shaders/quad.fs.glsl', VFS.RAW)
	local simpleShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'simpleShader')
	simpleShader:Initialize()

	math.randomseed(os.clock())
	local shapes = {}
	local pallet = PALLETS[math.random(#PALLETS)]
	local position = {}
	for i=1, SPHERE_COUNT*4, 4 do
		position[i+0] = math.random()  -- x
		position[i+1] = math.random()  -- y
		position[i+2] = math.random()  -- z
		position[i+3] = 1.0 -- padding
	end
	local speed = {}
	for i=1, SPHERE_COUNT*4, 4 do
		speed[i+0] = math.random()+0.25 -- vx
		speed[i+1] = math.random()+0.25 -- vy
		speed[i+2] = math.random()+0.25 -- vz
		speed[i+3] = 1.0 -- padding
	end
	local radius = {}
	for i=1, SPHERE_COUNT*4, 4 do
		radius[i+0] = math.random() + 0.5 -- r
		radius[i+1] = 0.0 -- padding
		radius[i+2] = 0.0 -- padding
		radius[i+3] = 0.0 -- padding
	end
	TableConcat(shapes, pallet)
	TableConcat(shapes, position)
	TableConcat(shapes, speed)
	TableConcat(shapes, radius)
	local shapeSSBO = {
		ssbo = nil,
		binding = 5,
		elementSize = 7,
		elementCount = 12 * SPHERE_COUNT + 16,
	}
	shapeSSBO.ssbo = gl.GetVBO(GL.ARRAY_BUFFER, true)
	shapeSSBO.ssbo:Define(12 * SPHERE_COUNT + 16, {
		{id = shapeSSBO.binding, name='spheres', size=1},
	})
	shapeSSBO.ssbo:Upload(shapes)

	local camera = {
		0.0, 0.0,-6.0, 1.0, -- cam_pos
		0.0, 0.0, 1.0, 1.0, -- cam_front
	   -1.0, 0.0, 0.0, 1.0, -- cam_xAxis
		0.0, 1.0, 0.0, 1.0, -- cam_yAxis
		45.0,               -- cam_fov
	}
	local cameraSSBO = {
		ssbo = nil,
		binding = 7,
		elementSize = 1,
		elementCount = 24, -- real = 17 but must be aligned
	}
	cameraSSBO.ssbo = gl.GetVBO(GL_ARRAY_BUFFER, true)
	cameraSSBO.ssbo:Define(cameraSSBO.elementCount, {
		{id = cameraSSBO.binding, name='Camera', size=cameraSSBO.elementSize}
	})
	cameraSSBO.ssbo:Upload(camera)
	local renderTexture = gl.CreateTexture(WIDTH, HEIGHT, {
		target = GL_TEXTURE_2D,
		boarder = false,
		min_filter = GL_NEAREST,
		mag_filter = GL_NEAREST,
		wrap_s = GL_CLAMP_TO_EDGE,
		wrap_t = GL_CLAMP_TO_EDGE,
		format = GL_RGBAF32,
	})

	local quad = Quad:new()

	local this = {
		computeShader = computeShader,
		simpleShader = simpleShader,
		renderTexture = renderTexture,
		shouldUpdateBuffers = true,
		shapeSSBO = shapeSSBO,
		cameraSSBO = cameraSSBO,
		timeUniformLoc = timeUniformLoc,
		time = 0,
		quad = quad,
	}

	function this:Draw()
		glUseShader(computeShader)
			local unit,level,layer = 0,0,0
			glBindImageTexture(unit, renderTexture, level, layer, GL_READ_WRITE, GL_RGBAF32)
			glTexture(unit, this.renderTexture)
			if this.shouldUpdateBuffers then
				this.shapeSSBO.ssbo:BindBufferRange(this.shapeSSBO.binding, 0, this.shapeSSBO.elementCount, GL_SHADER_STORAGE_BUFFER)
				this.cameraSSBO.ssbo:BindBufferRange(this.cameraSSBO.binding, 0, this.cameraSSBO.elementCount, GL_SHADER_STORAGE_BUFFER)
				this.shouldUpdateBuffers = false
			end
			glUniform(this.timeUniformLoc, this.time)
			glDispatchCompute(WIDTH, HEIGHT, 1, GL_SHADER_IMAGE_ACCESS_BARRIER_BIT) -- GL_ALL_BARRIER_BITS
		simpleShader:Activate()
			glBlending(GL_SRC_ALPHA, GL_ONE)
			glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
			quad:draw()
			glBlending(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
		simpleShader:Deactivate()
	end

	function this:on_Update(dt)
		this.time = this.time + dt;
	end

	function this:Delete()
		if computeShader ~= nil then --[[ computeShader:Delete() ]] end
		if simpleShader ~= nil then simpleShader:Delete() end

		if shapeSSBO.ssbo ~= nil then shapeSSBO.ssbo:Delete() end
		if cameraSSBO.ssbo ~= nil then cameraSSBO.ssbo:Delete() end
	
		if quad ~= nil then quad:Delete() end
	end

	return this
end

return BlobsMascot