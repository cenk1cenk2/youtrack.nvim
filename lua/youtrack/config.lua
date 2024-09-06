---@class youtrack.Config
---@field url string
---@field token string
---@field ui youtrack.ConfigUI

---@class youtrack.ConfigUI
---@field border 'double' | 'none' | 'rounded' | 'shadow' | 'single' | 'solid'

---@type youtrack.Config
local M = {
	ui = {
		border = "single",
	},
}

return M
