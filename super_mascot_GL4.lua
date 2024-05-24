-- File: super_mascot_GL4.lua

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
		name    = 'Super Mascot GL4',
		desc    = 'Manages mascots',
		author  = 'chmod777',
		date    = 'May 2024',
		license = 'GNU AGPL v3',
		layer   = 0,
		enabled = true,
	}
end

-- TODO
-- look into why advplayerlist parent scale is different than ui_scale

local fbo = nil

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')

local Quad, FBO = VFS.Include(luaWidgetDir..'chmod777_includes/utilities_GL4.lua')

local quadVsSrc = VFS.LoadFile(luaWidgetDir..'chmod777_includes/shaders/quad_centering.vs.glsl', VFS.RAW)
local quadFsSrc = VFS.LoadFile(luaWidgetDir..'chmod777_includes/shaders/quad_alpha.fs.glsl', VFS.RAW)

local quadShader = nil
local quadUniformLocs = {
	screenPos = nil,
	imgSize = nil,
	viewGeometry = nil
}
local quad = nil

local playerListTop,playerListLeft = 0,0
local updatePositionTimer = 0
local updatePositionInterval = 2

local uiScale = 1
local viewGeometryX,viewGeometryY = 0,0

local imgSizeX,imgSizeY = 140,140
local usedImgSizeX,usedImgSizeY = imgSizeX,imgSizeY -- * uiScale
local posX,posY = 0,0
local baseOffsetX,baseOffsetY = 0,0
local offsetX,offsetY = baseOffsetX,baseOffsetY -- * uiScale

local shouldUpdateImgSize = true
local shouldUpdateViewGeometry = true
local shouldUpdatePosition = true

local currentOption = nil
local requestOption = nil

local mascots = {}
local CommanderMascot
local commander
local SimpleMascot
local simple
local BlobsMascot
local blobs


local glClear = gl.Clear
local glDepthTest = gl.DepthTest
local glDepthMask = gl.DepthMask
local glViewport = gl.Viewport
local glTexture = gl.Texture
local glUniform = gl.Uniform
local glGetUniformLocation = gl.GetUniformLocation
local GL_TRIANGLES = GL.TRIANGLES
local GL_COLOR_BUFFER_BIT = GL.COLOR_BUFFER_BIT
local GL_DEPTH_BUFFER_BIT = GL.DEPTH_BUFFER_BIT

local spGetConfigFloat = Spring.GetConfigFloat
local spGetViewGeometry = Spring.GetViewGeometry
local spEcho = Spring.Echo

---------------------------------------------------------------------------------------------------
--  fowrard declared function
---------------------------------------------------------------------------------------------------

local RegisterMascot = nil
local DeregisterMascot = nil

local updatePosition = nil

function widget:Initialize()
	fbo = FBO:new(imgSizeX, imgSizeY, true)

	quadShader = LuaShader({
		vertex = quadVsSrc,
		fragment = quadFsSrc,
	}, 'Quad Shader')
	local quadShaderCompiled = quadShader:Initialize()
	if quadShaderCompiled ~= true then
		spEcho('Super Mascot GL4: Quad Shader: compilation failed')
		widgetHandler:RemoveWidget()
		return
	end

	local shader = quadShader.shaderObj;
	quadUniformLocs.screenPos = glGetUniformLocation(shader, 'screenPos')
	quadUniformLocs.imgSize = glGetUniformLocation(shader, 'imgSize')
	quadUniformLocs.viewGeometry = glGetUniformLocation(shader, 'viewGeometry')

	quad = Quad:new(0, 0)

	viewGeometryX,viewGeometryY = spGetViewGeometry()
	updatePosition(true)

	CommanderMascot = VFS.Include(luaWidgetDir.."chmod777_includes/super_mascot/commander.lua")
	commander = CommanderMascot:new()
end

function widget:Shutdown()
	if fbo ~= nil then fbo:Delete() end
	if quadShader ~= nil then quadShader:Delete() end
	if quad ~= nil then quad:Delete() end

	if commander ~= nil then commander:Delete() end
end

function widget:TextCommand(command)
	if command:sub(1, 6) == 'mascot' then
		local name = command:sub(8)
		requestOption = name
		if mascots[name] then
			currentOption = name
		end
	end
end
-- called before Initialization
function widget:SetConfigData(data)
	if data.currentOption ~= nil then
		currentOption = data.currentOption
	end
	if data.requestOption ~= nil then
		requestOption = data.requestOption
	end
end
-- called after Initialization
function widget:GetConfigData()
	return {
		currentOption = currentOption,
		requestOption = requestOption,
	}
end

function widget:Update(dt)
	-- For when other advPlayerList menues are enabled/disabled or resized
	updatePositionTimer = updatePositionTimer + dt
	if updatePositionTimer > updatePositionInterval then
		updatePositionTimer = 0
		updatePosition(false)
	end

	commander:on_Update(dt)
end
function widget:GameFrame(n)
	commander:on_GameFrame(n)
end
function widget:PlayerChanged()
	commander:on_PlayerChanged()
end
function widget:UnitDestroyed(unitID)
	commander:on_UnitDestroyed(unitID)
end


function widget:ViewResize(vx, vy)
	updatePosition(true)
	viewGeometryX,viewGeometryY = vx, vy
	shouldUpdateViewGeometry = true
end

function widget:DrawScreen()
	local currentMascot = mascots[currentOption]
	if true or currentMascot and currentMascot.func then
		glViewport(0, 0, imgSizeX, imgSizeY)
		fbo:bind()
			glDepthTest(true)
			glDepthMask(true)
			glClear(GL_DEPTH_BUFFER_BIT)
			glClear(GL_COLOR_BUFFER_BIT, 0,0,0,0)
			commander:Draw()
			glDepthTest(false)
			glDepthMask(false)
		fbo:unbind()
		glViewport(0, 0, viewGeometryX, viewGeometryY)
	else
		currentOption = nil
		fbo:bind()
			glDepthTest(true)
			glDepthMask(true)
			glClear(GL_DEPTH_BUFFER_BIT)
			glClear(GL_COLOR_BUFFER_BIT, 0,0,0,0)
			glDepthTest(false)
			glDepthMask(false)
		fbo:unbind()
	end

	quadShader:Activate()
		glTexture(0, fbo.tex)
		if shouldUpdateImgSize then
			glUniform(quadUniformLocs.imgSize, usedImgSizeX, usedImgSizeY)
			shouldUpdateImgSize = false
		end
		if shouldUpdatePosition then
			glUniform(quadUniformLocs.screenPos, posX, posY)
			shouldUpdatePosition = false
		end
		if shouldUpdateViewGeometry then
			glUniform(quadUniformLocs.viewGeometry, viewGeometryX, viewGeometryY)
			shouldUpdateViewGeometry = false
		end
		quad.VAO:DrawElements(GL_TRIANGLES)
		glTexture(0, false)
	quadShader:Deactivate()
end

function updatePosition(force)
	if force == nil then force = false end
	
	local newUiScale = spGetConfigFloat('ui_scale', 1) or 1
	local uiScaleChanged = newUiScale ~= uiScale
	if (force or uiScaleChanged) then
		uiScale = newUiScale
		usedImgSizeX = imgSizeX * uiScale
		usedImgSizeY = imgSizeY * uiScale
		shouldUpdateImgSize = true
		offsetX = baseOffsetX * uiScale
		offsetY = baseOffsetY * uiScale
	end

	local prevTop,prevLeft = playerListTop,playerListLeft
	if WG.displayinfo ~= nil or
		WG.unittotals ~= nil or
		WG.music ~= nil or
		WG['advplayerlist_api'] ~= nil
	then
		local playerListPos
		if WG.displayinfo ~= nil then
			playerListPos = WG.displayinfo.GetPosition()
		elseif WG.unittotals ~= nil then
			playerListPos = WG.unittotals.GetPosition()
		elseif WG.music ~= nil then
			playerListPos = WG.music.GetPosition()
		elseif WG['advplayerlist_api'] ~= nil then
			playerListPos = WG['advplayerlist_api'].GetPosition()
		end
		playerListTop,playerListLeft = playerListPos[1],playerListPos[2]
	else
		playerListTop,playerListLeft = 0,viewGeometryX-usedImgSizeX
	end

	if (force or
		uiScaleChanged or
		prevTop == nil or
		prevTop ~= playerListTop or
		prevLeft ~= playerListLeft)
	then
		posX = playerListLeft + offsetX
		posY = playerListTop + offsetY
		shouldUpdatePosition = true
	end
end
