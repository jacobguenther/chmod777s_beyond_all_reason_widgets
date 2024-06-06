-- File: super_mascot/commander.lua

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
-- do something about multiple commanders
-- always update matrices for only the current commander
-- cloak animation
-- nano particles

local glGetUniformLocation = gl.GetUniformLocation
local glUniform = gl.Uniform
local glCulling = gl.Culling
local glDepthTest = gl.DepthTest
local glDepthMask = gl.DepthMask
local glTexture = gl.Texture
local glUnitShapeTextures = gl.UnitShapeTextures

local GL_BACK = GL.BACK
local GL_UNSIGNED_INT = GL.UNSIGNED_INT

local spEcho = Spring.Echo
local spGetMyPlayerID = Spring.GetMyPlayerID
local spGetMyTeamID = Spring.GetMyTeamID
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetTeamUnits = Spring.GetTeamUnits
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitRotation = Spring.GetUnitRotation
local spSetUnitAlwaysUpdateMatrix = Spring.SetUnitAlwaysUpdateMatrix

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

local layout = {
	{id = 6, name = 'worldposrot', size = 4},
	-- {id = 7, name = 'camEye', size = 4},
	-- {id = 8, name = 'camTarget', size = 4},
	-- {id = 9, name = 'perspParams', size = 4},
	{id = 10, name = 'instData', type = GL_UNSIGNED_INT, size = 4}
}

local CommanderMascot = {}
function CommanderMascot:new()
	local DrawUnitCustomGL4 = VFS.Include(luaWidgetDir..'chmod777_includes/DrawUnitCustom_GL4.lua')
	local drawUnitCustomGL4 = DrawUnitCustomGL4:new()

	local vsSrc = VFS.LoadFile(luaWidgetDir..'chmod777_includes/shaders/draw_unit_custom.vs.glsl', VFS.RAW)
	local fsSrc = VFS.LoadFile(luaWidgetDir..'chmod777_includes/shaders/draw_unit_custom.fs.glsl', VFS.RAW)
	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	vsSrc = vsSrc:gsub('//__ENGINEUNIFORMBUFFERDEFS__', engineUniformBufferDefs)
	fsSrc = fsSrc:gsub('//__ENGINEUNIFORMBUFFERDEFS__', engineUniformBufferDefs)
	local unitShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
	}, 'DrawUnitCustomGL4 Shader')
	local unitshaderCompiled = unitShader:Initialize()
	if unitshaderCompiled ~= true then
		spEcho('DrawUnitCustomGL4 shader compilation failed')
		return nil
	end

	local shader = unitShader.shaderObj
	local cameraEyeLocation = glGetUniformLocation(shader, "iCamEye")
	local cameraTargetLocation = glGetUniformLocation(shader, "iCamTarget")
	local perspectiveLocation = glGetUniformLocation(shader, "iPerspParams")

	local isCommander = {}
	for unitDefID,def in ipairs(UnitDefs) do
		if def.customParams.iscommander then
			isCommander[unitDefID] = true
		end
	end

	local this = {
		gameStarted = false,
		drawUnitCustomGL4 = drawUnitCustomGL4,
		renderID = nil,
		unitShader = unitShader,
		currentPlayerID = nil,
		currentTeamID = nil,
		currentAllyTeamID = nil,
		isCommander = isCommander,
		currentCommanderDefID = nil,
		currentCommanderID = nil,
		commanderNormal = nil,
		camEx = 0.0, camEy = 35.0, camEz = -70,
		camTx = 0.0, camTy = 0.0, camTz = 0.0,
		near = 0.1, far = 250.0, fovy = math.rad(120), aspect = 1.0,
		cameraEyeLocation = cameraEyeLocation,
		cameraTargetLocation = cameraTargetLocation,
		perspectiveLocation = perspectiveLocation,
	}

	function this:updatePlayer()
		this.currentPlayerID = spGetMyPlayerID()
		this.currentTeamID = spGetMyTeamID()
		this.currentAllyTeamID = spGetMyAllyTeamID()
	end
	function this:updateCommander()
		if this.currentCommanderID then
			spSetUnitAlwaysUpdateMatrix(this.currentCommanderID, false)
		end

		this.currentCommanderDefID = nil
		this.currentCommanderID = nil
		this.commanderNormal = nil

		local units = spGetTeamUnits(this.currentTeamID)
		for i=1,#units do
			local unitID = units[i]
			local unitDefID = spGetUnitDefID(unitID)
			if isCommander[unitDefID] then
				this.currentCommanderDefID = unitDefID
				this.currentCommanderID = unitID

				this:updateCommanderNormal()

				spSetUnitAlwaysUpdateMatrix(this.currentCommanderID, true)

				-- local name = UnitDefs[this.currentCommanderDefID].objectname
				-- spEcho(name, Spring.GetModelPieceMap)
				-- if Spring.GetModelPieceMap then
				-- 	local piece_map = Spring.GetModelPieceMap("Units/armcom.s3o")
				-- 	local formatted = ""
				-- 	for name,index in pairs(piece_map) do
				-- 		formatted = formatted.." "..name.." "..index
				-- 	end
				-- 	spEcho(formatted)
				-- end
				break
			end
		end
	end
	function this:updateCommanderNormal()
		local def = UnitDefs[this.currentCommanderDefID]
		if def and def.customParams and def.customParams.normaltex then
			this.commanderNormal = def.customParams.normaltex
		end
	end

	function this:on_DrawGenesis()
		unitShader:Activate()
		glUniform(this.cameraEyeLocation,
			this.camEx,
			this.camEy,
			this.camEz)
		glUniform(this.cameraTargetLocation,
			this.camTx,
			this.camTy,
			this.camTz)
		glUniform(this.perspectiveLocation,
			this.near,
			this.far,
			this.fovy,
			1.0)
		unitShader:Deactivate()
		widgetHandler:RemoveCallIn("DrawGenesis")
	end

	function this:Draw()
		if this.currentCommanderDefID == nil then
			return
		end
		glCulling(GL_BACK)
		glDepthTest(true)
		glDepthMask(true)
		this.unitShader:Activate()
			glUnitShapeTextures(this.currentCommanderDefID, true)
			glTexture(3, this.commanderNormal)

			this.drawUnitCustomGL4:GetUnitCustomVAO(this.currentCommanderDefID, layout).VAO:Submit()
			
			glTexture(3, false)
			glUnitShapeTextures(this.currentCommanderDefID, false)
		this.unitShader:Deactivate()
		glDepthMask(false)
		glCulling(false)
	end

	function this:on_Update(dt)
		if this.currentCommanderID == nil then
			return
		end

		local pitch, yaw, roll = spGetUnitRotation(this.currentCommanderID)
		if yaw ~= nil and yaw ~= this.prevYaw then
			this.prevYaw = yaw
			-- local dirX, dirY, dirZ = Spring.GetUnitDirection(this.currentCommanderID)
			-- local px, py, pz, midX, midY, midZ, aimX, aimY, aimZ = Spring.GetUnitPosition(this.currentCommanderID, true)
			-- local isCloacked = Spring.GetUnitIsCloaked(this.currentCommanderID);

			local px, py, pz = 0.0, -35, 0.0

			local instanceData = {
				px, py, pz,-yaw, -- posrot
				0,   0,  0,   0  -- instData
			}
			this.renderID = drawUnitCustomGL4:AddUnit(this.currentCommanderID, this.currentCommanderDefID, layout, instanceData, this.renderID)
		end
	end
	function this:on_GameFrame(n)
		if not this.gameStarted and n > 0 then
			this.gameStarted = true
			this:updatePlayer()
			this:updateCommander()
		end
	end
	function this:on_PlayerChanged()
		local oldCommanderID = this.currentCommanderID
		local oldCommanderDefID = this.currentCommanderDefID
		this:updatePlayer()
		this:updateCommander()
		if this.currentCommanderID ~= oldCommanderID and this.renderID ~= nil then
			this.drawUnitCustomGL4:RemoveUnit(layout, oldCommanderDefID, this.renderID)
			this.renderID = nil
		end
	end
	function this:on_UnitDestroyed(unitID)
		if unitID == this.currentCommanderID then
			if this.renderID ~= nil then
				drawUnitCustomGL4:RemoveUnit(layout, this.currentCommanderDefID, this.renderID)
				this.renderID = nil
			end
			this:updateCommander()
		end
	end

	function this:Delete()
		if this.unitShader then
			unitShader:Finalize()
		end
	
		if this.renderID ~= nil then
			this.drawUnitCustomGL4:RemoveUnit(layout, this.currentCommanderDefID, this.renderID)
			this.renderID = nil
		end

		if this.drawUnitCustomGL4 ~= nil then
			this.drawUnitCustomGL4:Delete()
		end
	end

	this:updatePlayer()
	this:updateCommander()
	this:on_Update(0)

	return this
end

return CommanderMascot
