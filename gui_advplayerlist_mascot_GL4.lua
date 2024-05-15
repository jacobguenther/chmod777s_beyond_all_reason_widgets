-- file: utilites_GL4.lua
-- author: chmod777
-- license: GNU GPL, v2 or later

function widget:GetInfo()
	return {
		name		= 'AdvPlayersList Mascot GL4',
		desc		= 'Shows a mascot sitting on top of the adv-playerlist  (use /mascot to switch)',
		author		= 'Floris, (GL4 by chmod777)',
		date		= '23 may 2015',
		license		= 'GNU GPL, v2 or later',
		layer		= 0,
		enabled		= false,
	}
end

---------------------------------------------------------------------------------------------------
--  Config
---------------------------------------------------------------------------------------------------

local imageDirectory			= ':l:'..LUAUI_DIRNAME..'Images/advplayerslist_mascot/'
local customImageDirectory		= LUAUI_DIRNAME..'Widgets/Images/advplayerslist_mascot/'

local OPTIONS = {}
OPTIONS.defaults = {	-- these will be loaded when switching style, but the style will overwrite the those values
	name				= 'Defaults',
	imageSize			= 55,
	xOffset				= -1.6,
	yOffset				= -58/5,
	blinkDuration		= 0.12,
	blinkTimeout		= 6,
}
table.insert(OPTIONS, {
	name				= 'Floris Cat',
	body				= imageDirectory..'floriscat_body.png',
	head				= imageDirectory..'floriscat_head.png',
	headblink			= imageDirectory..'floriscat_headblink.png',
	santahat			= imageDirectory..'santahat.png',
	imageSize			= 53,
	xOffset				= -1.6,
	yOffset				= -58/5,
	head_xOffset		= 0,
	head_yOffset		= 0,
})
table.insert(OPTIONS, {
	name				= 'GrumpyCat',
	body				= imageDirectory..'grumpycat_body.png',
	head				= imageDirectory..'grumpycat_head.png',
	headblink			= imageDirectory..'grumpycat_headblink.png',
	santahat			= imageDirectory..'santahat.png',
	imageSize			= 53,
	xOffset				= -1.6,
	yOffset				= -58/5,
	head_xOffset		= 0,
	head_yOffset		= 0,
})
table.insert(OPTIONS, {
	name				= "Teifion's MrBeans",
	body				= imageDirectory..'mrbeans_body.png',
	head				= imageDirectory..'mrbeans_head.png',
	headblink			= imageDirectory..'mrbeans_headblink.png',
	santahat			= imageDirectory..'santahat.png',
	imageSize			= 50,
	xOffset				= -1.6,
	yOffset				= -58/4,
	head_xOffset		= -0.01,
	head_yOffset		= 0.13,
})

---------------------------------------------------------------------------------------------------
-- Add custom mascots here
---------------------------------------------------------------------------------------------------

table.insert(OPTIONS, {
	name				= 'Doge',
	body				= customImageDirectory..'dogedog_full.png',
	head				= nil,
	headblink			= nil,
	santahat			= imageDirectory..'santahat.png',
	imageSize			= 50,
	xOffset				= 0,
	yOffset				= -8,
	head_xOffset		= 5/100,
	head_yOffset		= 6/100,
})

---------------------------------------------------------------------------------------------------
--  Declarations
---------------------------------------------------------------------------------------------------

local currentOption = 1

local usedImgSize = OPTIONS[currentOption].imageSize
local chobbyInterface

local xPos = 0
local yPos = 0

local isBlinking = false
local blinkStart = nil
local blinkEnd = nil
local rot = 0
local bob = 0

local positionChanged = false
local xOffset = 0
local yOffset = 0
local xHeadOffset = 0
local yHeadOffset = 0

local mascotChanged = false
local bodyTexture = nil
local headTexture = nil
local head = nil
local headblink = nil
local hatTexture = nil

local mascotVAO = nil
local mascotVBO = nil
local mascotIndexVBO = nil
local mascotInstanceVBO = nil
local confettiParticleCount = 60
local maxElements = 3  + confettiParticleCount
local baseElements = 0
local extendedElements = 0

local mascotShaderWrapper = nil
local mascotShader = nil
local shaderConfig = {}

local math_isInRect = math.isInRect
local pi = math.pi
local sin = math.sin
local random = math.random
local floor = math.floor

local gl_Texture = gl.Texture
local gl_UseShader = gl.UseShader
local gl_Uniform = gl.Uniform

local GL_TRIANGLES = GL.TRIANGLES

local luaShaderDir = 'LuaUI/Widgets/Include/'
local LuaShader = VFS.Include(luaShaderDir..'LuaShader.lua')
VFS.Include(luaShaderDir..'instancevbotable.lua')

local function shallow_copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		t2[k] = v
	end
	return t2
end

local OPTIONS_original = shallow_copy(OPTIONS)
OPTIONS_original.defaults = nil

---------------------------------------------------------------------------------------------------
-- Santa hats in December
---------------------------------------------------------------------------------------------------

local drawSantahat = false
if os.date('%m') == '12'  and  os.date('%d') >= '12' then
	drawSantahat = true
end

---------------------------------------------------------------------------------------------------
-- GL Stuff
---------------------------------------------------------------------------------------------------

local vsSrc = [[
#version 420
precision highp int;
precision highp float;

// vertex attributes
layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

// instance attributes
layout (location = 2) in ivec4 instanceFlags;      // see buildInstanceVBOData
layout (location = 3) in vec2 confettiStartPos;
layout (location = 4) in float confettiSpeed;
layout (location = 5) in float confettiRandomSeed;

uniform vec2 viewGeometry; // x, y
uniform vec2 screenPos;    // x, y
uniform float imgSize;
uniform vec4 offsets;      // offset.xy, headOffset.xy
uniform vec2 bobRotation;  // x -> bob, y -> rotation
uniform float confettiTime;

const float CONFETTI_SCALE = 0.05;

out DataVS {
	vec2 uv;
	float drawHead;
	float drawHat;
	float isConfetti;
	float confettiPalletIndex;
} vs_out;

vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

void main() {
	int isConfettiI = instanceFlags.x & 0x10;
	bool isConfetti = bool(isConfettiI);

	vs_out.uv = uv;
	vs_out.drawHead = float(instanceFlags.x & 0x04);
	vs_out.drawHat = float(instanceFlags.x & 0x08);
	vs_out.isConfetti = float(isConfettiI);
	vs_out.confettiPalletIndex = float(instanceFlags.y);

	bool useHeadRotation = bool(instanceFlags.x & 0x01);
	bool useHeadOffset = bool(instanceFlags.x & 0x02);

	vec2 offset = offsets.xy;
	vec2 headOffset = offsets.zw;
	float bob = bobRotation.x;
	float rotation = bobRotation.y;

	vec2 imgSize2 = vec2(imgSize);
	
	vec2 coord = coords.xy;
	vec2 translate = screenPos.xy;

	if (useHeadOffset) {
		translate += fma(headOffset, imgSize2, vec2(0.0, 7));
	}
	if (useHeadRotation) {
		// Center, rotate, then uncenter.
		// Note that the quad has coords 0->1.
		coord = rotate(coords.xy - 0.5, radians(rotation)) + 0.5;

		translate.y += bob;
	}


	if (isConfetti) {
		imgSize2 *= CONFETTI_SCALE;

		vec2 travel = vec2(confettiTime) * vec2(confettiRandomSeed, confettiSpeed);
		float ground = confettiRandomSeed * 0.1; // so that they don't stack up in a line
		if (travel.y < confettiStartPos.y - ground) {
			translate += confettiStartPos - vec2(sin(travel.x), travel.y);
		} else {
			translate += vec2(confettiStartPos.x, ground);
		}
	}

	coord = fma(coord, imgSize2, vec2(translate)) / viewGeometry.xy;
	coord = fma(coord, vec2(2.0), vec2(-1.0));

	gl_Position = vec4(coord.x, coord.y, 0, 1);
}
]]

local fsSrc = [[
#version 330

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (binding = 0) uniform sampler2D body;
layout (binding = 1) uniform sampler2D head;
layout (binding = 2) uniform sampler2D hat;

const vec3 CONFETTI_PALLET[5] = {
	vec3(0.6588, 0.3922, 0.9922), // purple
	vec3(0.1608, 0.8039, 1.0),    // blue
	vec3(0.4706, 1.0,    0.2667), // green
	vec3(1.0,    0.4431, 0.5529), // red
	vec3(0.9922, 1.0,    0.4157), // yellow
};
const float CONFETTI_ALPHA = 0.6;

in DataVS {
	vec2 uv;
	float drawHead;
	float drawHat;
	float isConfetti;
	float confettiPalletIndex;
} vs_in;

out vec4 fragColor;

void main() {
	bool drawHeadB = vs_in.drawHead > 0.5;
	bool drawHatB = vs_in.drawHat > 0.5;
	bool isConfettiB = vs_in.isConfetti > 0.5;
	int palletIndex = int(vs_in.confettiPalletIndex);

	vec4 textureSample = texture(body, vs_in.uv);
	if (drawHeadB) {
		textureSample = texture(head, vs_in.uv);
	}
	if (drawHatB) {
		textureSample = texture(hat, vs_in.uv);
	}

	if (isConfettiB) {
		fragColor.xyz = CONFETTI_PALLET[palletIndex];
		fragColor.a = CONFETTI_ALPHA;
	} else {
		fragColor = textureSample;
	}
}
]]

local screenPosUniformLoc = nil
local drawHeadUniformLoc = nil
local imgSizeUniformLoc = nil
local offsetsUniformLoc = nil
local bobRotationUniformLoc = nil
local viewGeometryUniformLoc = nil
local confettiTimeUniformLoc = nil

function initShader()
	mascotShaderWrapper = LuaShader({
		vertex = vsSrc:gsub('//__DEFINES__', LuaShader.CreateShaderDefinesString(shaderConfig)),
		fragment = fsSrc:gsub('//__DEFINES__', LuaShader.CreateShaderDefinesString(shaderConfig)),
		uniformInt = {},
		uniformFloat = {}
	}, 'mascotShader')
	local shaderCompiled = mascotShaderWrapper:Initialize()

	if not shaderCompiled then
		Spring.Echo('Failed to compile mascotShader GL4')
		local shLog = gl.GetShaderLog() or ''
		Spring.Echo(shLog)
		widgetHandler:RemoveWidget()
	end
	
	mascotShader = mascotShaderWrapper.shaderObj

	screenPosUniformLoc = gl.GetUniformLocation(mascotShader, 'screenPos')
	imgSizeUniformLoc = gl.GetUniformLocation(mascotShader, 'imgSize')
	offsetsUniformLoc = gl.GetUniformLocation(mascotShader, 'offsets')
	bobRotationUniformLoc = gl.GetUniformLocation(mascotShader, 'bobRotation')
	viewGeometryUniformLoc = gl.GetUniformLocation(mascotShader, 'viewGeometry')
	confettiTimeUniformLoc = gl.GetUniformLocation(mascotShader, 'confettiTime')
end

local function TableConcat(t1,t2)
	for i=1,#t2 do
		t1[#t1+1] = t2[i]
	end
	return t1
end
local function ZeroExtend(t, n)
	while #t <= 7 do
		t[#t+1] = 0
	end
	return t
end

local function buildInstanceVBOData()
	-- x flags
	--  1 - useHeadRotation
	--  2 - useHeadOffset
	--  4 - drawHead
	--  8 - drawHat
	-- 16 - isConfetti
	-- y confetti pallet
	--  0-purple, 1-blue, 2-green, 3-red, 4-yellow
	-- z,w unused
	-- confetti starting position x, y
	-- confetti random seead
	local USE_HEAD_ROTATION = 1
	local USE_HEAD_OFFSET = 2
	local DRAW_HEAD = 4
	local DRAW_HAT = 8
	local IS_CONFETTI = 16

	local instanceVBOData = {}
	local numFields = 8
	baseElements = 0

	if bodyTexture ~= nil then
		local bodyInstanceData = {}
		ZeroExtend(bodyInstanceData, numFields)
		TableConcat(instanceVBOData, bodyInstanceData)
		baseElements = baseElements + 1
	end

	if headTexture ~= nil then
		local headInstanceData = {USE_HEAD_ROTATION+USE_HEAD_OFFSET+DRAW_HEAD}
		ZeroExtend(headInstanceData, numFields)
		TableConcat(instanceVBOData, headInstanceData)
		baseElements = baseElements + 1
	end

	if drawSantahat and hatTexture ~= nil then
		local hatInstanceData
		if headTexture == nil then
			hatInstanceData = {USE_HEAD_OFFSET+DRAW_HAT}
		else
			hatInstanceData = {USE_HEAD_ROTATION+USE_HEAD_OFFSET+DRAW_HAT}
		end
		ZeroExtend(hatInstanceData, numFields)
		TableConcat(instanceVBOData, hatInstanceData)
		baseElements = baseElements + 1
	end

	for i = baseElements, baseElements+confettiParticleCount-1 do
		local confettiIndex = floor(random(0,4))
		local startX = random(0,70)
		local startY = random(80,120)
		local confettiSpeed = random(50, 80)
		local confettiRandomSeed = random(10, 20)
		instanceVBOData[i*8+1] = IS_CONFETTI
		instanceVBOData[i*8+2] = confettiIndex
		instanceVBOData[i*8+3] = 0
		instanceVBOData[i*8+4] = 0
		instanceVBOData[i*8+5] = startX
		instanceVBOData[i*8+6] = startY
		instanceVBOData[i*8+7] = confettiSpeed
		instanceVBOData[i*8+8] = confettiRandomSeed
	end

	return instanceVBOData
end

local function initGLBuffers()
	mascotVAO = gl.GetVAO()
	if mascotVAO == nil then
		Spring.Echo('Mascot GL4: Failed to get VAO')
		widgetHandler:RemoveWidget()
	end

	mascotVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if mascotVBO == nil then
		Spring.Echo('Mascot GL4: Failed to get ARRAY_BUFFER VBO')
		widgetHandler:RemoveWidget()
	end
	local minX,minY = 0,0
	local maxX,maxY = 1,1
	local minU,minV = 0,1
	local maxU,maxV = 1,0

	local rectVBOData = {
		minX,minY, minU,minV, --bl
		minX,maxY, minU,maxV, --br
		maxX,maxY, maxU,maxV, --tr
		maxX,minY, maxU,minV, --tl
	}
	local numVertices = 4
	mascotVBO:Define(numVertices, {
		{id = 0, name = 'coords', size = 2, type = GL.FLAOT},
		{id = 1, name = 'uv', size = 2, type = GL.FLAOT},
	})
	mascotVBO:Upload(rectVBOData)
	mascotVAO:AttachVertexBuffer(mascotVBO)
	
	mascotIndexVBO = gl.GetVBO(GL.ELEMENT_ARRAY_BUFFER, false)
	if mascotVBO == nil then
		Spring.Echo('Mascot GL4: Failed to get ELEMENT_ARRAY_BUFFER VBO')
		widgetHandler:RemoveWidget()
	end
	local indexVBOData = {
		2, 1, 0,
		3, 2, 0,
	}
	local numIndices = 6
	mascotIndexVBO:Define(numIndices)
	mascotIndexVBO:Upload(indexVBOData)
	mascotVAO:AttachIndexBuffer(mascotIndexVBO)

	mascotInstanceVBO = gl.GetVBO(GL.ARRAY_BUFFER, false)
	if mascotInstanceVBO == nil then
		Spring.Echo('Mascot GL4: Failed to get ARRAY_BUFFER VBO')
		widgetHandler:RemoveWidget()
	end
	local instanceVBOLayout = {
		{id = 2, name = 'instanceFlags', size = 4, type = GL.INT},
		{id = 3, name = 'confettiStartOffset', size = 2, type = GL.FLAOT},
		{id = 4, name = 'confettiSpeed', size = 1, type = GL.FLAOT},
		{id = 5, name = 'confettiRandomSeed', size = 1, type = GL.FLAOT},
	}
	mascotInstanceVBO:Define(maxElements, instanceVBOLayout)
	mascotVAO:AttachInstanceBuffer(mascotInstanceVBO)

	return true
end

---------------------------------------------------------------------------------------------------
-- Manage Options
---------------------------------------------------------------------------------------------------

local function toggleOptions(option)
	if OPTIONS[option] then
		currentOption = option
	else
		currentOption = currentOption + 1
		if not OPTIONS[currentOption] then
			currentOption = 1
		end
	end
	
	loadOption()
	updatePosition(true)
end

function loadOption()
	local appliedOption = OPTIONS_original[currentOption]
	OPTIONS[currentOption] = shallow_copy(OPTIONS.defaults)

	for option, value in pairs(appliedOption) do
		OPTIONS[currentOption][option] = value
	end

	if currentOption > 3 then
		local imageFiles = VFS.DirList(customImageDirectory)
		local foundBody = false
		local bodyPath = OPTIONS[currentOption]['body']
		for i=1, #imageFiles do
			local windowsPathAsSTD = imageFiles[i]:gsub('\\', '/')
			if (bodyPath == imageFiles[i]) or (bodyPath == windowsPathAsSTD) then
				foundBody = true
				break
			end
		end
		if not foundBody then
			Spring.Echo('Missing file: '..OPTIONS[currentOption]['body']..' Going to next mascot.')
			toggleOptions()
			return
		end
	end

	mascotChanged = true
	bodyTexture = OPTIONS[currentOption]['body']
	head = OPTIONS[currentOption]['head']
	headblink = OPTIONS[currentOption]['headblink']
	hatTexture = OPTIONS[currentOption]['santahat']
	xOffset = OPTIONS[currentOption]['xOffset']
	yOffset = OPTIONS[currentOption]['yOffset']
	xHeadOffset = OPTIONS[currentOption]['head_xOffset']
	yHeadOffset = OPTIONS[currentOption]['head_yOffset']
	if not isBlinking or headBlink == nil then
		headTexture = head
	else
		headTexture = headBlink
	end

	blinkStart = OPTIONS[currentOption]['blinkTimeout']
	blinkEnd = blinkStart + OPTIONS[currentOption]['blinkDuration']

	if mascotInstanceVBO then
		local instanceVBOData = buildInstanceVBOData()
		mascotInstanceVBO:Upload(instanceVBOData)
	end
end

function widget:MousePress(mx, my, mb)
	if mb == 1 and math_isInRect(mx, my, xPos, yPos, xPos+usedImgSize, yPos+usedImgSize) then
		toggleOptions()
	end
end

function widget:TextCommand(command)
	if string.sub(command, 1, 6) == 'mascot' then
		toggleOptions(tonumber(string.sub(command, 8)))
		Spring.Echo('Playerlist mascot: '..OPTIONS[currentOption].name)
	end
end

function widget:GetConfigData()
	return {currentOption = currentOption}
end

function widget:SetConfigData(data)
	if data.currentOption ~= nil and OPTIONS[data.currentOption] ~= nil then
		currentOption = data.currentOption or currentOption
	end
end

---------------------------------------------------------------------------------------------------
-- Updates
---------------------------------------------------------------------------------------------------

local updateViewGeometry = true
function widget:ViewResize()
	updatePosition(true)
	updateViewGeometry = true
end

local parentPos = {}
function updatePosition(force)
	local prevPos = parentPos
	if WG['displayinfo'] ~= nil then
		parentPos = WG['displayinfo'].GetPosition()
	elseif WG['unittotals'] ~= nil then
		parentPos = WG['unittotals'].GetPosition()
	elseif WG['music'] ~= nil then
		parentPos = WG['music'].GetPosition()
	elseif WG['advplayerlist_api'] ~= nil then
		parentPos = WG['advplayerlist_api'].GetPosition()
	else
		local scale = (vsy / 880) * (1 + (Spring.GetConfigFloat('ui_scale', 1) - 1) / 1.25)
		parentPos = {0,vsx-(220*scale),0,vsx,scale}
	end

	local parentLeft = parentPos[2]  -- x
	local parentTop = parentPos[1]   -- y
	local parentScale = parentPos[5]

	if (force or
		prevPos[1] == nil or
		prevPos[1] ~= parentTop or
		prevPos[2] ~= parentLeft or
		prevPos[5] ~= parentScale)
	then
		positionChanged = true
		usedImgSize = OPTIONS[currentOption]['imageSize'] * parentScale
		xPos = parentLeft + (xOffset * parentScale)
		yPos = parentTop + (yOffset * parentScale)
	end
end

local totalTime = 0

local blinkTimer = 0

local animationInterval = 1/30
local animationTimer = 0
local updateBobRotation = false

local updatePositionTimer = 0
local updatePositionInterval = 2

local doConfettiAnimation = true
local confettiTime = 0
local confettiInterval = 5

function widget:Update(dt)
	totalTime=totalTime+dt

	animationTimer=animationTimer+dt
	if animationTimer > animationInterval then
		updateBobRotation = true
		bob = 1.5*sin(pi*(totalTime/5.5))
		rot = 12 + 6*sin(pi*(totalTime/4))
		animationTimer=0
	end

	blinkTimer=blinkTimer+dt
	if (not isBlinking) and (headblink ~= nil) and (blinkTimer > blinkStart) then
		isBlinking = true
		headTexture = headblink
	end
	if isBlinking and (blinkTimer > blinkEnd) then
		isBlinking = false
		headTexture = head
		blinkTimer = 0
	end

	if doConfettiAnimation then
		confettiTime=confettiTime+dt
		if confettiTime > confettiInterval then
			confettiTime = 0
			extendedElements = 0
			doConfettiAnimation = false
		end
	end

	-- For when other advPlayerList menues are enabled/disabled or resize
	updatePositionTimer = updatePositionTimer + dt
	if updatePositionTimer > updatePositionInterval then
		updatePositionTimer = 0
		updatePosition()
	end
end

function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
	local name = UnitDefs[unitDefID].name;
	if name == 'armdecom' or name == 'coredecom' then
		extendedElements = confettiParticleCount
		doConfettiAnimation = true
	end
end

function widget:Initialize()
	initShader()
	initGLBuffers()
	loadOption()
	updatePosition()
end

function widget:Shutdown()
	if mascotShader ~= nil then
		mascotShaderWrapper:Delete()
	end
	if mascotInstanceVBO ~= nil then
		mascotInstanceVBO:Delete()
	end
	if mascotIndexVBO ~= nil then
		mascotIndexVBO:Delete()
	end
	if mascotVBO ~= nil then
		mascotVBO:Delete()
	end
	if mascotVAO ~= nil then
		mascotVAO:Delete()
	end
end

function widget:RecvLuaMsg(msg, playerID)
	if msg:sub(1,18) == 'LobbyOverlayActive' then
		chobbyInterface = (msg:sub(1,19) == 'LobbyOverlayActive1')
	end
end

function widget:DrawScreen()
	if chobbyInterface then return end

	if bodyTexture then
		gl_Texture(0, bodyTexture)
	end
	if headTexture then
		gl_Texture(1, headTexture)
	end
	if hatTexture then
		gl_Texture(2, hatTexture)
	end

	gl_UseShader(mascotShader)
		if updateBobRotation then
			gl_Uniform(bobRotationUniformLoc, bob, rot)
			updateBobRotation = false
		end

		if positionChanged then
			gl_Uniform(screenPosUniformLoc, xPos, yPos)
			positionChanged = false
		end

		if mascotChanged then
			gl_Uniform(imgSizeUniformLoc, usedImgSize)
			gl_Uniform(offsetsUniformLoc, xOffset, yOffset, xHeadOffset, yHeadOffset)
			mascotChanged = false
		end
		
		if doConfettiAnimation then
			gl_Uniform(confettiTimeUniformLoc, confettiTime)
		end

		if updateViewGeometry then
			local x, y = Spring.GetViewGeometry()
			gl_Uniform(viewGeometryUniformLoc, x, y)
		end

		local usedElements = baseElements + extendedElements
		if usedElements > 0 then
			mascotVAO:DrawElements(GL_TRIANGLES, 6, 0, usedElements, 0, 0)
		end
	gl_UseShader(0)

	gl_Texture(0, false)
	gl_Texture(1, false)
	gl_Texture(2, false)
end

