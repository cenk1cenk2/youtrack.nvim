local M = {
	_ = {},
}

local n = require("nui-components")
local utils = require("youtrack.utils")

---@param c youtrack.Config
---@return table
function M.error_tab(c)
	return n.tab(
		{ id = "error" },
		n.rows(
			{ flex = 1 },
			n.buffer({
				id = "error",
				border_style = c.ui.border,
				flex = 1,
				buf = utils.create_buffer(false),
				autoscroll = false,
				border_label = "Error",
			})
		)
	)
end

return M
