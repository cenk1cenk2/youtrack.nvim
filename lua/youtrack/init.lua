local M = {
	get_issues = require("youtrack.issues").get_issues,
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local c = require("youtrack.config")

---@param config youtrack.Config
function M.setup(config)
	vim.tbl_deep_extend("force", c, config or {})

	log.setup()
	lib.setup(config)
end

return M
