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

return M
