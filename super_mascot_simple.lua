function widget:GetInfo()
	return {
		name    = 'Super Mascot Simple',
		desc    = 'Use any png as a mascot.\nRequires Super Mascot GL(super_mascot_GL4.lua).\nActivate with /mascot <image_name>. Do not include the file extension.',
		author  = 'chmod777',
		date    = 'July 2023',
		license = 'AGPLv3',
		layer   = 1,
		enabled = false,
	}
end

local luaWidgetDir = 'LuaUI/Widgets/'
VFS.Include(luaWidgetDir..'utilities_GL4.lua')
local vsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/quad.vs.glsl', VFS.RAW)
local fsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/quad.fs.glsl', VFS.RAW)
local imgDir = luaWidgetDir..'super_mascot/images/'

local luaIncludeDir = luaWidgetDir..'Include/'
VFS.Include(luaIncludeDir..'instancevbotable.lua')
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

local shader = nil
local quad = nil

local mascot_names = {}

local glTexture = gl.Texture
local spEcho = Spring.Echo

function Draw(texturePath)
	shader:Activate()
		glTexture(0, texturePath)
		quad:draw()
		glTexture(0, false)
	shader:Deactivate()
end

function widget:Initialize()
	shader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'shader')
	shader:Initialize()

	quad = Quad:new(-1, -1, 1, 1, true)

	spEcho("Simple Mascot: Checking Image Directory", imgDir)
	local images = VFS.DirList(imgDir, '*.png')
	for i=1, #images do
		local path = images[i]
		spEcho(i, path)
		local namePlusExtension = path:match('[^/]+$')
		if #namePlusExtension == 0 then
			-- on windows
			namePlusExtension = path:match('[^\\]+$')
		end
		local name = namePlusExtension:match('[^%.]+')
		local extension = namePlusExtension:match('%.png')
		spEcho(i, namePlusExtension)
		spEcho(i, path, name, extension)
		mascot_names[#mascot_names+1] = name
		WG.RegisterMascot(name, Draw, path)
	end
end

function widget:Shutdown()
	for i=1, #mascot_names do 
		local name = mascot_names[i]
		WG.DeregisterMascot(name)
	end
	if shader ~= nil then
		shader:Delete()
	end
	if quad ~= nil then
		quad:delete()
	end
end