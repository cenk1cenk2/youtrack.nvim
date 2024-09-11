local M = {}

function M.set_component_value(component, value)
	component:set_current_value(value)
	local lines = component:get_lines()
	vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, true, lines)
	component:redraw()
end

return M
