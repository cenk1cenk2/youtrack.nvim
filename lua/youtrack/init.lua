local M = {
	get_issues = require("youtrack.issues").get_issues,
}

---@param config youtrack.Config
function M.setup(config)
	local c = require("youtrack.config").setup(config)

	local log = require("youtrack.log").setup({ level = c.log_level })

	require("youtrack.lib").setup(c)

	log.debug("Plugin has been setup: %s", c)
end

return M
