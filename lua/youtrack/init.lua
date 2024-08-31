local M = {}

local lib = require("youtrack.lib")
local log = require("youtrack.log")

---@class youtrack.Config
---@field url string The hostname of the instance

---@param config youtrack.Config
function M.setup(config)
	vim.print(vim.inspect(lib.setup(config)))
end

function M.get_issues()
	vim.print(vim.inspect(lib.get_issues()))
end

return M
