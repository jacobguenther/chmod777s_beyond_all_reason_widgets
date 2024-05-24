-- File: blobs.lua



local GL_RGBAF32 = 34836

local luaWidgetDir = 'LuaUI/Widgets/'
local Quad, FBO = VFS.Include(luaWidgetDir..'utilities_GL4.lua')
local computeSource = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/ray_march.glsl', VFS.RAW)
local vsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/quad.vs.glsl', VFS.RAW)
local fsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/quad.fs.glsl', VFS.RAW)

local luaIncludeDir = luaWidgetDir..'Include/'
VFS.Include(luaIncludeDir..'instancevbotable.lua')
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

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


local computeShader = nil
local timeUniformLoc = nil
local shapeSSBO = {
	ssbo = nil,
	binding = 5,
	elementSize = 7,
	elementCount = 12 * SPHERE_COUNT + 16,
}
local cameraSSBO = {
	ssbo = nil,
	binding = 7,
	elementSize = 1,
	elementCount = 24, -- real = 17 but must be aligned
}
shouldUpdateBuffers = true

local renderTexture = nil

local BuildRenderSurface
local RenderToSurface

local time = 0;

local simpleShader = nil
local quad = nil

function Draw()
	gl.UseShader(computeShader)
		local unit,level,layer = 0,0,0
		gl.BindImageTexture(unit, renderTexture, level, layer, GL.READ_WRITE, GL_RGBAF32)
		gl.Texture(unit, renderTexture)
		if shouldUpdateBuffers then
			shapeSSBO.ssbo:BindBufferRange(shapeSSBO.binding, 0, shapeSSBO.elementCount, GL.SHADER_STORAGE_BUFFER)
			cameraSSBO.ssbo:BindBufferRange(cameraSSBO.binding, 0, cameraSSBO.elementCount, GL.SHADER_STORAGE_BUFFER)
			shouldUpdateBuffers = false
		end
		gl.Uniform(timeUniformLoc, time)
		gl.DispatchCompute(WIDTH, HEIGHT, 1, GL.SHADER_IMAGE_ACCESS_BARRIER_BIT) -- GL.ALL_BARRIER_BITS
	simpleShader:Activate()
		gl.Blending(GL.SRC_ALPHA, GL.ONE)
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
		quad:draw()
		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	simpleShader:Deactivate()
end

local function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end

function widget:Initialize()
	computeShader = gl.CreateShader({
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
	if (computeShader == nil) then
		widgetHandler:RemoveWidget()
		return
	end
	timeUniformLoc = gl.GetUniformLocation(computeShader, 'time');

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
	cameraSSBO.ssbo = gl.GetVBO(GL.ARRAY_BUFFER, true)
	cameraSSBO.ssbo:Define(cameraSSBO.elementCount, {
		{id = cameraSSBO.binding, name='Camera', size=cameraSSBO.elementSize}
	})
	cameraSSBO.ssbo:Upload(camera)
	renderTexture = gl.CreateTexture(WIDTH, HEIGHT, {
		target = GL_TEXTURE_2D,
		boarder = false,
		min_filter = GL.NEAREST,
		mag_filter = GL.NEAREST,
		wrap_s = GL.CLAMP_TO_EDGE,
		wrap_t = GL.CLAMP_TO_EDGE,
		format = GL_RGBAF32,
	})

	simpleShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'simpleShader')
	simpleShader:Initialize()

	quad = Quad:new()

	WG.RegisterMascot('blobs', Draw, nil)
end

function widget:Update(dt)
	time = time + dt;
end

function widget:Shutdown()
	if computeShader ~= nil then
		-- computeShader:Delete()
	end
	if shapeSSBO.ssbo ~= nil then
		shapeSSBO.ssbo:Delete()
	end
	if cameraSSBO.ssbo ~= nil then
		cameraSSBO.ssbo:Delete()
	end

	if simpleShader ~= nil then
		simpleShader:Delete()
	end

	if quad ~= nil then
		quad:Delete()
	end

	if WG.DeregisterMascot then
		WG.DeregisterMascot('blobs')
	end
end
