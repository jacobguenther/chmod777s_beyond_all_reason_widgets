-- File: layout.lua

-- RESOURCES
--   https://www.w3.org/TR/2011/REC-CSS2-20110607/#minitoc
--   https://github.com/tensor-programming/rust_browser_part_4/blob/master/src/layout.rs

local luaWidgetDir = 'LuaUI/Widgets/'

local Element = VFS.Include(luaWidgetDir..'chmod777_includes/html_css/element.lua')

local Rect = {}
function Rect:new(x, y, width, height)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	if width == nil then width = 0 end
	if height == nil then height = 0 end

	local this = {
		x = x,
		y = y,
		width = width,
		height = height,
	}
	function this:expand(edge_size)
		local new_x = this.x - edge_size.left
		local new_y = this.y - edge_size.top
		local new_width = this.width + edge_size.left + edge_size.right
		local new_height = this.height + edge_size.top + edge_size.bottom
		return Rect:new(new_x, new_y, new_width, new_height)
	end

	function this:print()
		Spring.Echo("x: "..this.x.." y: "..this.y.." w: "..this.width.." h: "..this.height)
	end

	return this
end

local EdgeSizes = {}
function EdgeSizes:new(top, right, bottom, left)
	if top == nil then top = 0 end
	if right == nil then right = 0 end
	if bottom == nil then bottom = 0 end
	if left == nil then left = 0 end

	local this = {
		top = top,
		right = right,
		bottom = bottom,
		left = left,
	}

	function this:print()
		Spring.Echo("t: "..this.top.." r: "..this.right.." b: "..this.bottom.." l: "..this.left)
	end

	return this
end

local BoxType = {
	"block",
	"inline",
	"inline-block",
	"anonymous",
}

local Dimensions = {}
---@param content Rect
---@param padding EdgeSizes
---@param border EdgeSizes
---@param margin EdgeSizes
---@param current Rect
---@return Dimensions
function Dimensions:new(content, padding, border, margin, current)
	if content == nil then content = Rect:new() end
	if padding == nil then padding = EdgeSizes:new() end
	if border == nil then border = EdgeSizes:new() end
	if margin == nil then margin = EdgeSizes:new() end
	if current == nil then current = Rect:new() end

	local this = {
		content = content,
		padding = padding,
		border = border,
		margin = margin,
		current = current,
	}

	function this:print()
		this.content:print()
		this.padding:print()
		this.border:print()
		this.margin:print()
	end

	---@return Rect
	function this:padding_box()
		return this.content:expand(this.padding)
	end
	---@return Rect
	function this:border_box()
		return this:padding_box():expand(this.border)
	end
	---@return Rect
	function this:margin_box()
		return this:border_box():expand(this.margin)
	end
	return this
end

local Layout = {}
function Layout:new(style_node, box_type, dimensions, children)
	if style_node == nil then end
	if box_type == nil then box_type = BoxType[1] end
	if dimensions == nil then dimensions = Dimensions:new() end
	if children == nil then children = {} end

	local this = {
		dimensions = dimensions,
		box_type = box_type,
		style_node = style_node,
		children = children,
	}

	function this:layout(parent_dim)
		local box_type = this.box_type
		if box_type == "block" then
			this:layout_block(parent_dim)
		elseif box_type == "inline" then
			this:layout_inline(parent_dim)
		elseif box_type == "inline-block" then
			this:layout_inline_block(parent_dim)
		elseif box_type == "anonymous" then
			this:layout_anonymous()
		end
	end
	function this:layout_block(parent_dim)
		this:calculate_width(parent_dim)
		this:calculate_position(parent_dim)
		this:layout_children()
		this:calculate_height(parent_dim)
	end
	function this:layout_inline(parent_dim)
	end
	function this:layout_inline_block(parent_dim)
		this:calculate_inline_width(parent_dim)
		this:calculate_inline_position(parent_dim)
		this:layout_children()
		this:calculate_height(parent_dim)
	end
	function this:layout_anonymous()
	end

	function this:calculate_width(parent_dim)
		local style_node = this.style_node
		local dimensions = this.dimensions

		local width = style_node:get_absolute_value_or("width", 0, parent_dim.content.width)
		dimensions.padding.left = style_node:get_absolute_value_or("padding-left", 0)
		dimensions.padding.right = style_node:get_absolute_value_or("padding-right", 0)
		dimensions.border.left = style_node:get_absolute_value_or("border-left-width", 0)
		dimensions.border.right = style_node:get_absolute_value_or("border-right-width", 0)
		local margin_left = style_node:get_declaration("margin-left", false)
		local margin_right = style_node:get_declaration("margin-right", false)
		local margin_left_value = style_node:get_absolute_value_or("margin-left", 0)
		local margin_right_value = style_node:get_absolute_value_or("margin-right", 0)

		local total = width
			+ dimensions.padding.left
			+ dimensions.padding.right
			+ dimensions.border.left
			+ dimensions.border.right
			+ margin_left_value
			+ margin_right_value

		local underflow = parent_dim.content.width - total
		
		if width == 0 then
			if underflow > 0 then
				dimensions.content.width = underflow
				dimensions.margin.right = margin_right_value
			else
				dimensions.content.width = width
				dimensions.margin.right = margin_right_value + underflow
			end
			dimensions.margin.left = margin_left_value
		elseif margin_left == nil and margin_right ~= nil then
			if width ~= 0 then
				dimensions.content.width = width
				dimensions.margin.left = underflow
				dimensions.margin.right = margin_right_value
			end
		elseif margin_left ~= nil and margin_right == nil then
			if width ~= 0 then
				dimensions.content.width = width
				dimensions.margin.left = margin_left_value
				dimensions.margin.right = underflow
			end
		elseif margin_left == nil and margin_right == nil then
			if width ~= 0 then
				dimensions.content.width = width
				dimensions.margin.left = underflow / 2
				dimensions.margin.right = underflow / 2
			end
		else
			dimensions.content.width = width
			dimensions.margin.left = margin_left_value
			dimensions.margin.right = margin_right_value + underflow
		end
	end
	function this:calculate_position(parent_dim)
		local style_node = this.style_node
		local dimensions = this.dimensions

		dimensions.padding.top = style_node:get_absolute_value_or("padding-top", 0)
		dimensions.padding.bottom = style_node:get_absolute_value_or("padding-bottom", 0)
		dimensions.border.top = style_node:get_absolute_value_or("border-top-width", 0)
		dimensions.border.bottom = style_node:get_absolute_value_or("border-bottom-width", 0)
		dimensions.margin.top = style_node:get_absolute_value_or("margin-top", 0)
		dimensions.margin.bottom = style_node:get_absolute_value_or("margin-bottom", 0)

		dimensions.content.x = parent_dim.content.x
			+ dimensions.padding.left
			+ dimensions.border.left
			+ dimensions.margin.left
		dimensions.content.y = parent_dim.content.height
			+ parent_dim.content.y
			+ dimensions.padding.top
			+ dimensions.border.top
			+ dimensions.margin.top
	end

	function this:calculate_inline_width(parent_dim)
		local style_node = this.style_node
		local dimensions = this.dimensions

		dimensions.content.width = style_node:get_absolute_value_or("width", 0, parent_dim.content.width)

		dimensions.padding.left = style_node:get_absolute_value_or("padding-left", 0)
		dimensions.padding.right = style_node:get_absolute_value_or("padding-right", 0)
		
		dimensions.border.left = style_node:get_absolute_value_or("border-left-width", 0)
		dimensions.border.right = style_node:get_absolute_value_or("border-right-width", 0)
		
		dimensions.margin.left = style_node:get_absolute_value_or("margin-left", 0)
		dimensions.margin.right = style_node:get_absolute_value_or("margin-right", 0)
	end
	function this:calculate_inline_position(parent_dim)
		local style_node = this.style_node
		local dimensions = this.dimensions

		dimensions.padding.top = style_node:get_absolute_value_or("padding-top", 0)
		dimensions.padding.bottom = style_node:get_absolute_value_or("padding-bottom", 0)
		
		dimensions.border.top = style_node:get_absolute_value_or("border-top-width", 0)
		dimensions.border.bottom = style_node:get_absolute_value_or("border-bottom-width", 0)
		
		dimensions.margin.top = style_node:get_absolute_value_or("margin-top", 0)
		dimensions.margin.bottom = style_node:get_absolute_value_or("margin-bottom", 0)

		dimensions.content.x = parent_dim.content.x
			+ parent_dim.current.x
			+ dimensions.padding.left
			+ dimensions.border.left
			+ dimensions.margin.left
		dimensions.content.y = parent_dim.content.height
			+ parent_dim.content.y
			+ dimensions.padding.top
			+ dimensions.border.top
			+ dimensions.margin.top
	end

	function this:layout_children()
		local dimensions = this.dimensions
		local max_child_height = 0
		local previous_box_type = "block"
		for c,child in ipairs(this.children) do
			if previous_box_type == "inline-block" then
				if child.box_type == "block" then
					dimensions.content.height = dimensions.content.height + max_child_height
					dimensions.current.x = 0
				end
			end

			child:layout(dimensions)

			local new_height = child.dimensions:margin_box().height
			if new_height > max_child_height then
				max_child_height = new_height
			end
			
			if child.box_type == "block" then
				dimensions.content.height = dimensions.content.height + child.dimensions:margin_box().height
			elseif child.box_type == "inline-block" then
				dimensions.current.x = dimensions.current.x + child.dimensions:margin_box().width
				if dimensions.current.x > dimensions.content.width then
					dimensions.content.height = dimensions.content.height + max_child_height
					dimensions.current.x = 0
					child:layout(dimensions)
					dimensions.current.x = dimensions.current.x + child.dimensions:margin_box().width
				end
			end

			previous_box_type = child.box_type
		end
	end
	function this:calculate_height(parent_dim)
		local style_node = this.style_node
		local dimensions = this.dimensions
		local height = style_node:get_absolute_value_or("height", 0, parent_dim.content.height)
		if height ~= nil then
			dimensions.content.height = height
		end
	end

	return this
end

function layout_tree(root, parent_dim)
	parent_dim.content.height = 0
	local root_box = build_layout_tree(root)
	root_box:layout(parent_dim)
	return root_box
end

function build_layout_tree(style_node)
	local display = style_node:get_value_or("display", "block")
	if display == "none" then
		display = "anonymous"
	end
	Spring.Echo("'"..display.."'")
	local layout_node = Layout:new(style_node, display)
	for i,child in ipairs(style_node.children) do
		local child_display = child:get_value_or("display", "block")
		if child_display ~= "none" then
			layout_node.children[#layout_node.children+1] = build_layout_tree(child)
		end
	end
	return layout_node
end

return {
	Rect = Rect,
	EdgeSizes = EdgeSizes,
	Dimensions = Dimensions,
	Layout = Layout,
	layout_tree = layout_tree,
	build_layout_tree = build_layout_tree,
}