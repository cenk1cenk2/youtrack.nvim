local M = {
	get_issues = require("youtrack.issues").get_issues,
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")

---@param config youtrack.Config
function M.setup(config)
	log.setup()
	require("youtrack.setup").setup(config)
	lib.setup(config)
end

return M
