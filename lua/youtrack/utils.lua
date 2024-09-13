local M = {}

---
---@param component any
---@param value? any
---@return any
function M.set_component_value(component, value)
	vim.schedule(function()
		if not value then
			value = component:get_current_value()
		end

		component:set_current_value(value)
		local lines = component:get_lines()
		vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, true, lines)
		component:redraw()
	end)

	return component
end

---
---@param component any
---@param content string | string[]
---@param modifable? boolean
---@return any
function M.set_component_buffer_content(component, content, modifable)
	---@type string[]
	local c
	if type(content) == "string" then
		c = vim.fn.split(content, "\n")
	elseif type(content) == "table" then
		c = content
	else
		c = { "" }
	end

	if modifable then
		vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, c)
	else
		component:modify_buffer_content(function()
			vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, c)
		end)
	end

	return component
end

---@param component any
---@return string[]
function M.get_component_buffer_content(component)
	return vim.api.nvim_buf_get_lines(component.bufnr, 0, -1, false)
end

---@param bufnr int
---@return string[] | nil
function M.get_buffer_content(bufnr)
	local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	if #content == 0 or (#content == 1 and content[1] == "") then
		return nil
	end

	return content
end

return M
