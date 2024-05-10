function widget:GetInfo()
	return {
		name      = 'DrawUnitCustom GL4',
		version   = 'v0.2',
		desc      = 'DrawUnitCustom GL4',
		author    = 'chmod777',
		date      = 'May 2024',
		license   = 'GNU GPL, v2 or later',
		layer     = -9999,
		enabled   = true,
	}
end

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
VFS.Include(luaIncludeDir..'instancevboidtable.lua')

local VBOTables = {}
local vertexVBO
local indexVBO

local uniqueID = 0

local spEcho = Spring.Echo
local glGetVBO = gl.GetVBO
local GL_UNSIGNED_INT = GL.UNSIGNED_INT
local GL_ARRAY_BUFFER = GL.ARRAY_BUFFER
local GL_ELEMENT_ARRAY_BUFFER = GL.ELEMENT_ARRAY_BUFFER

local function CreateVBOTable(layout, unitDefID)
	local maxElements = #layout
	local unitIDAttributeIndex
	for i=1, #layout do
		local attrib = layout[i]
		if attrib.name == 'instData'
			and attrib.type == GL_UNSIGNED_INT
			and attrib.size == 4
		then
			unitIDAttributeIndex = attrib.id
			break
		end
	end
	if unitIDAttributeIndex == nil then
		return nil
	end
	local instanceTable = makeInstanceVBOTable(layout, maxElements, 'tableName', unitIDAttributeIndex, 'unitID')
	instanceTable.VAO = makeVAOandAttach(vertexVBO, instanceTable.instanceVBO, indexVBO)
	instanceTable.indexVBO = indexVBO
	instanceTable.vertexVBO = vertexVBO
	return instanceTable
end

---config table with {layoutVBO, instanceData}
function DrawUnitCustomGL4(unitID, unitDefID, layout, data, updateID)
	if not updateID then 
		uniqueID = uniqueID + 1
		updateID = uniqueID
	end

	local DrawUnitVBOTable
	if VBOTables[layout] then
		if VBOTables[layout][unitDefID] then
			DrawUnitVBOTable = VBOTables[layout][unitDefID]
		else
			DrawUnitVBOTable = CreateVBOTable(layout, unitDefID)
			VBOTables[layout][unitDefID] = DrawUnitVBOTable
		end
	else
		DrawUnitVBOTable = CreateVBOTable(layout, unitDefID)
		VBOTables[layout] = {[unitDefID] = DrawUnitVBOTable}
	end
	if DrawUnitVBOTable == nil then
		spEcho('Layout must contain valid instData attribute')
		return nil
	end

	local elementID = pushElementInstance(
		DrawUnitVBOTable,
		data,
		updateID,
		true,
		false,
		unitID,
		'unitID')
	return updateID
end

function GetUnitCustomVAO(unitDefID, layout)
	if VBOTables[layout] and VBOTables[layout][unitDefID] then
		return VBOTables[layout][unitDefID]
	end
end

function StopDrawUnitCustomGL4(layout, unitDefID, uniqueID)
	if VBOTables[layout]
		and VBOTables[layout][unitDefID]
		and VBOTables[layout][unitDefID].instanceIDtoIndex[uniqueID]
	then
		popElementInstance(VBOTables[layout][unitDefID], uniqueID)
	else
		spEcho('Unable to remove what you wanted in StopDrawUnitCustomGL4', uniqueID)
	end
end

function widget:Initialize()
	vertexVBO = glGetVBO(GL_ARRAY_BUFFER, false)
	indexVBO = glGetVBO(GL_ELEMENT_ARRAY_BUFFER, false)
	vertexVBO:ModelsVBO()
	indexVBO:ModelsVBO()

	WG['DrawUnitCustomGL4'] = DrawUnitCustomGL4
	WG['StopDrawUnitCustomGL4'] = StopDrawUnitCustomGL4
	WG['GetUnitCustomVAO'] = GetUnitCustomVAO
	widgetHandler:RegisterGlobal('DrawUnitCustomGL4')
	widgetHandler:RegisterGlobal('StopDrawUnitCustomGL4')
	widgetHandler:RegisterGlobal('GetUnitCustomVAO')
end

function widget:Shutdown()
	for layout,layoutTable in pairs(VBOTables) do
		for unitDefID,unitTable in pairs(layoutTable) do
			if unitTable.VAO then
				unitTable.instanceVBO:Delete()
				unitTable.VAO:Delete()
			end
		end
	end

	if vertexVBO ~= nil then
		vertexVBO:Delete()
	end
	if indexVBO ~= nil then
		indexVBO:Delete()
	end

	WG['DrawUnitCustomGL4'] = nil
	WG['StopDrawUnitCustomGL4'] = nil
	WG['GetUnitCustomVAO'] = nil
	widgetHandler:DeregisterGlobal('DrawUnitCustomGL4')
	widgetHandler:DeregisterGlobal('StopDrawUnitCustomGL4')
	widgetHandler:DeregisterGlobal('GetUnitCustomVAO')
end
