local M = {
	get_issues = require("youtrack.issues").get_issues,
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")

---@param config youtrack.Config
function M.setup(config)
	log.setup()
	local c = require("youtrack.setup").setup(config)
	lib.setup(c)
end

return M
