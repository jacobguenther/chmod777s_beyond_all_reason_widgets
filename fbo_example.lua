function widget:GetInfo()
	return {
		name    = 'A minimal FBO example',
		desc    = '',
		author  = 'chmod777',
		date    = 'May 2024',
		license = 'AGPLv3',
		layer   = 0,
		enabled = true,
	}
end

local fbo = nil

local luaWidgetDir = 'LuaUI/Widgets/'
local luaIncludeDir = luaWidgetDir..'Include/'
local LuaShader = VFS.Include(luaIncludeDir..'LuaShader.lua')
VFS.Include(luaWidgetDir..'utilities_GL4.lua')

local quadVsSrc = [[
	#version 420

	layout (location = 0) in vec2 coords;
	layout (location = 1) in vec2 uv;
	
	uniform vec2 viewGeometry;
	uniform vec2 screenPos;
	uniform float imgSize;
	
	out DataVS {
		vec2 uv;
	} vs_out;
	
	void main() {
		vs_out.uv = uv;
	
		vec2 coord = coords;
	
		coord = fma(coord, vec2(imgSize*0.5), screenPos) / viewGeometry;
		coord = fma(coord, vec2(2.0), vec2(-1.0));
	
		gl_Position = vec4(coord, 0.0, 1.0);
	}
]]
local quadFsSrc = [[
	#version 420

	#extension GL_ARB_uniform_buffer_object : require
	#extension GL_ARB_shading_language_420pack: require
	
	layout (binding = 0) uniform sampler2D img;
	
	in DataVS {
		vec2 uv;
	} vs_in;
	
	out vec4 fragColor;
	
	void main() {
		fragColor = texture(img, vs_in.uv);
	}
]]
local quadShader = nil
local quadUniformLocs = {}
local quad = nil

local vsSrc = [[
#version 420

layout (location = 0) in vec2 coords;
layout (location = 1) in vec2 uv;

out DataVS {
	vec2 uv;
} vs_out;

void main() {
	vs_out.uv = uv;
	gl_Position = vec4(coords, 0.0, 1.0);
}
]]

local fsSrc = [[
#version 420

#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

layout (binding = 0) uniform sampler2D imgTop;
layout (binding = 1) uniform sampler2D imgLeft;
layout (binding = 2) uniform sampler2D imgRight;

const vec2 OFFSET_TOP = vec2(0.0, 0.0);
const vec2 OFFSET_LEFT = vec2(0.4, 0.0);
const vec2 OFFSET_RIGHT = vec2(-0.3, 0.0);

in DataVS {
	vec2 uv;
} vs_in;

out vec4 fragColor;

void main() {
	vec2 uv = vs_in.uv;
	vec4 top = texture(imgTop, uv + OFFSET_TOP);
	vec4 left = texture(imgLeft, uv + OFFSET_LEFT);
	vec4 right = texture(imgRight, uv + OFFSET_RIGHT);

	if (uv.y < 0.5) {
		fragColor = top;
		if (1 - uv.x < uv.y) {
			fragColor = right;
		}
		if (uv.x < uv.y) {
			fragColor = left;
		}
	} else if (uv.x > 0.5) {
		fragColor = right;
	} else {
		fragColor = left;
	}
}
]]
local combiningShader = nil
local combiningQuad = nil
local imgSize = 256

---------------------------------------------------------------------------------------------------
--  fowrard declared function
---------------------------------------------------------------------------------------------------

function widget:Initialize()
	combiningShader = LuaShader({
		vertex = vsSrc,
		fragment = fsSrc,
		uniformFloat = {},
		uniformInt = {},
		textures = {}
	}, 'Img Shader')
	local combiningShaderCompiled = combiningShader:Initialize()
	if not combiningShaderCompiled then
		Spring.Echo('Img Shader: compilation failed')
		widgetHandler:RemoveWidget()
	end
	combiningQuad = Quad:new(-1,-1, 1, 1, true)

	quadShader = LuaShader({
		vertex = quadVsSrc,
		fragment = quadFsSrc,
		uniformFloat = {},
		uniformInt = {},
		textures = {}
	}, 'Quad Shader')
	local quadShaderCompiled = quadShader:Initialize()
	if not quadShaderCompiled then
		Spring.Echo('Quad Shader: compilation failed')
		widgetHandler:RemoveWidget()
	end

	local shader = quadShader.shaderObj;
	quadUniformLocs['screenPos'] = gl.GetUniformLocation(shader, 'screenPos')
	quadUniformLocs['imgSize'] = gl.GetUniformLocation(shader, 'imgSize')
	quadUniformLocs['viewGeometry'] = gl.GetUniformLocation(shader, 'viewGeometry')

	quad = Quad:new()

	fbo = FBO:new(imgSize, imgSize, false)
end

function widget:Shutdown()
	if fbo ~= nil then
		fbo:delete()
	end

	if quadShader ~= nil then
		quadShader:Delete()
	end
	if combineShader ~= nil then
		combineShader:Delete()
	end

	if quad ~= nil then
		quad:delete()
	end
	if combiningQuad ~= nil then
		combiningQuad:delete()
	end
end

function DrawCombined()
	combiningShader:Activate()
		gl.Texture(0, "unitpics/armcom.dds")
		gl.Texture(1, "unitpics/corcom.dds")
		gl.Texture(2, "unitpics/armgeo.dds")
		combiningQuad:draw()
		gl.Texture(0, false)
		gl.Texture(1, false)
		gl.Texture(2, false)
	combiningShader:Deactivate()
end

function widget:DrawScreen()
	local viewGeometryX,viewGeometryY = Spring.GetViewGeometry()

	gl.Viewport(0, 0, imgSize, imgSize)
		-- Show preview in bottom of screen
		DrawCombined()

		-- render to a texture(fbo.tex)
		fbo.bind()
			gl.Clear(GL.COLOR_BUFFER_BIT, 0,0,0,0)
			DrawCombined()
		fbo.unbind()
	gl.Viewport(0, 0, viewGeometryX, viewGeometryY)

	-- display the texture on a quad in the center of the screen
	quadShader:Activate()
		gl.Texture(0, fbo.tex)
		gl.Uniform(quadUniformLocs['imgSize'], imgSize)
		gl.Uniform(quadUniformLocs['screenPos'], viewGeometryX/2, viewGeometryY/2)
		gl.Uniform(quadUniformLocs['viewGeometry'], viewGeometryX, viewGeometryY)
		quad:draw()
		gl.Texture(0, false)
	quadShader:Deactivate()
end
