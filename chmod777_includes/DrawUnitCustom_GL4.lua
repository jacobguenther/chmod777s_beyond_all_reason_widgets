-- File: DrawUnitCustom_GL4.lua

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


local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
VFS.Include(luaIncludeDir..'instancevboidtable.lua')

local spEcho = Spring.Echo
local glGetVBO = gl.GetVBO
local GL_UNSIGNED_INT = GL.UNSIGNED_INT
local GL_ARRAY_BUFFER = GL.ARRAY_BUFFER
local GL_ELEMENT_ARRAY_BUFFER = GL.ELEMENT_ARRAY_BUFFER

local DrawUnitCustomGL4 = {}
function DrawUnitCustomGL4:new()
	local vertexVBO = glGetVBO(GL_ARRAY_BUFFER, false)
	local indexVBO = glGetVBO(GL_ELEMENT_ARRAY_BUFFER, false)
	vertexVBO:ModelsVBO()
	indexVBO:ModelsVBO()

	local this = {
		VBOTables = {},
		vertexVBO = vertexVBO,
		indexVBO = indexVBO,
		uniqueID = 0,
	}

	function this:CreateVBOTable(layout, unitDefID)
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
		instanceTable.VAO = makeVAOandAttach(this.vertexVBO, instanceTable.instanceVBO, this.indexVBO)
		instanceTable.indexVBO = this.indexVBO
		instanceTable.vertexVBO = this.vertexVBO
		return instanceTable
	end

	function this:AddUnit(unitID, unitDefID, layout, data, updateID)
		if not updateID then 
			this.uniqueID = this.uniqueID + 1
			updateID = this.uniqueID
		end
	
		local DrawUnitVBOTable
		if this.VBOTables[layout] then
			if this.VBOTables[layout][unitDefID] then
				DrawUnitVBOTable = this.VBOTables[layout][unitDefID]
			else
				DrawUnitVBOTable = this:CreateVBOTable(layout, unitDefID)
				this.VBOTables[layout][unitDefID] = DrawUnitVBOTable
			end
		else
			DrawUnitVBOTable = this:CreateVBOTable(layout, unitDefID)
			this.VBOTables[layout] = {[unitDefID] = DrawUnitVBOTable}
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

	function this:GetUnitCustomVAO(unitDefID, layout)
		if this.VBOTables[layout] and this.VBOTables[layout][unitDefID] then
			return this.VBOTables[layout][unitDefID]
		end
	end
	
	function this:RemoveUnit(layout, unitDefID, uniqueID)
		if this.VBOTables[layout]
			and this.VBOTables[layout][unitDefID]
			and this.VBOTables[layout][unitDefID].instanceIDtoIndex[uniqueID]
		then
			popElementInstance(this.VBOTables[layout][unitDefID], uniqueID)
		else
			spEcho('Unable to remove what you wanted in StopDrawUnitCustomGL4', uniqueID)
		end
	end

	function this:Delete()
		for layout,layoutTable in pairs(this.VBOTables) do
			for unitDefID,unitTable in pairs(layoutTable) do
				if unitTable.VAO then
					unitTable.instanceVBO:Delete()
					unitTable.VAO:Delete()
				end
			end
		end
	
		if this.vertexVBO ~= nil then
			vertexVBO:Delete()
		end
		if this.indexVBO ~= nil then
			indexVBO:Delete()
		end	
	end

	return this
end

return DrawUnitCustomGL4
