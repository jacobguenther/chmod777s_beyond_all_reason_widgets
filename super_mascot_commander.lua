function widget:GetInfo()
	return {
		name    = 'Super Mascot Commander',
		desc    = 'Have your commander as your mascot.\nRequires super_mascot_GL4.lua(Super Mascot GL4) and DrawUnitCustom_GL4.lua(DrawUnitCustom GL4).\nActivate with /moscot comm',
		author  = 'chmod777',
		date    = 'April 2024',
		license = 'AGPLv3',
		layer   = 1,
		enabled = false,
	}
end

-- TODO
-- do something about multiple commanders
-- always update matrices for only the current commander
-- cloak animation
-- nano particles

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

local unitShaderConfig = {
	STATICMODEL = 0.0, -- do not touch!
	TRANSPARENCY = 0.5, -- transparency of the stuff drawn
	SKINSUPPORT = Script.IsEngineMinVersion(105, 0, 1653) and 1 or 0,
}
local vsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/draw_unit_custom.vs.glsl', VFS.RAW)
local fsSrc = VFS.LoadFile(luaWidgetDir..'super_mascot/shaders/draw_unit_custom.fs.glsl', VFS.RAW)
local unitShader

local isCommander = {}
local myCommanderDefID
local myCommanderID

local myPlayerID
local myTeamID
local myAllyTeamID

local renderID = nil
local layout = {
	{id = 6, name = 'worldposrot', size = 4},
	{id = 7, name = 'camEye', size = 4},
	{id = 8, name = 'camTarget', size = 4},
	{id = 9, name = 'perspParams', size = 4},
	{id = 10, name = 'parameters', size = 4},
	{id = 11, name = 'instData', type = GL.UNSIGNED_INT, size = 4}
}

function Draw()
	if renderID ~= nil and myCommanderDefID ~= nil and WG.GetUnitCustomVAO then
		gl.Culling(GL.BACK)
		gl.DepthTest(true)
		gl.DepthMask(true)
		unitShader:Activate()
			gl.UnitShapeTextures(myCommanderDefID, true)
			WG.GetUnitCustomVAO(myCommanderDefID, layout).VAO:Submit()
			gl.UnitShapeTextures(myCommanderDefID, false)
		unitShader:Deactivate()
		gl.DepthMask(false)
		gl.Culling(false)
	end
end

function initPlayer()
	myPlayerID = Spring.GetMyPlayerID()
	myTeamID = Spring.GetMyTeamID()
	myAllyTeamID = Spring.GetMyAllyTeamID()

	local units = Spring.GetTeamUnits(myTeamID)
	for i=1,#units do
		local unitID = units[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		if isCommander[unitDefID] then
			myCommanderDefID = unitDefID
			myCommanderID = unitID
			break
		end
	end
end

function widget:Initialize()
	if not WG.RegisterMascot then
		widgetHandler:RemoveWidget()
		return
	end

	for unitDefID,def in ipairs(UnitDefs) do
		if def.customParams.iscommander then
			isCommander[unitDefID] = true
		end
	end

	initPlayer()

	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	vsSrc = vsSrc:gsub('//__ENGINEUNIFORMBUFFERDEFS__', engineUniformBufferDefs)
	fsSrc = fsSrc:gsub('//__ENGINEUNIFORMBUFFERDEFS__', engineUniformBufferDefs)
	unitShader = LuaShader({
		vertex = vsSrc:gsub('//__DEFINES__', LuaShader.CreateShaderDefinesString(unitShaderConfig)),
		fragment = fsSrc:gsub('//__DEFINES__', LuaShader.CreateShaderDefinesString(unitShaderConfig)),
		uniformInt = {
			tex1 = 0,
			tex2 = 1,
		},
		uniformFloat = {
			iconDistance = 1,
		  },
	}, 'DrawUnitCutomGL4 Shader')
	local unitshaderCompiled = unitShader:Initialize()
	if unitshaderCompiled ~= true then
		Spring.Echo('DrawUnitShape shader compilation failed', unitshaderCompiled)
		widgetHandler:RemoveWidget()
	end

	WG.RegisterMascot('comm', Draw)
end

local camEx, camEy, camEz = 0.0, 25.0, 80.0
local camTx, camTy, camTz = 0.0, 25.0, 0.0
local near, far, fovy = 0.001, 200, math.rad(120)
local prevYaw = nil
function widget:Update(dt)
	if myCommanderID == nil then
		return
	end
	local pitch, yaw, roll = Spring.GetUnitRotation(myCommanderID)
	if yaw ~= prevYaw and WG.DrawUnitCustomGL4 then
		prevYaw = yaw
		-- local dirX, dirY, dirZ = Spring.GetUnitDirection(myCommanderID)
		-- local posX, posY, posZ, midX, midY, midZ, aimX, aimY, aimZ = Spring.GetUnitPosition(myCommanderID)
		-- local isCloacked = Spring.GetUnitIsCloaked(myCommanderID);

		local alpha = 1
		local isStatic = 0

		local instanceData = {
			0,       -20,     0, yaw, -- posrot
			camEx, camEy, camEz,   0, -- camEye
			camTx, camTy, camTz,   0, -- camTarget
			near,    far,  fovy,   0, -- perspParams
			alpha, isStatic,  0,   0, -- params
			0, 0, 0, 0                -- instData
		}
		renderID = WG.DrawUnitCustomGL4(myCommanderID, myCommanderDefID, layout, instanceData, renderID)
	end
end

local gameStarted = false
function widget:GameFrame(n)
	if not gameStarted and n > 0 then
		gameStarted = true
		initPlayer()
	end
end

function widget:PlayerChanged(playerID)
	local oldCommanderID = myCommanderID
	local oldCommanderDefID = myCommanderDefID
	initPlayer()
	if myCommanderID ~= oldCommanderID and renderID ~= nil and WG.StopDrawUnitCustomGL4 then
		WG.StopDrawUnitCustomGL4(layout, oldCommanderDefID, renderID)
		renderID = nil
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	if unitID == myCommanderID then
		if renderID ~= nil and WG.StopDrawUnitCustomGL4 then
			WG.StopDrawUnitCustomGL4(layout, myCommanderDefID, renderID)
			renderID = nil
		end
		myCommanderID = nil
		myCommanderDefID = nil
	end
end

function widget:Shutdown()
	if unitShader then
		unitShader:Finalize()
	end

	if renderID ~= nil and WG.StopDrawUnitCustomGL4 then
		WG.StopDrawUnitCustomGL4(layout, myCommanderDefID, renderID)
		renderID = nil
	end

	if WG.DeregisterMascot then
		WG.DeregisterMascot('comm')
	end
end