local M = {
	get_queries = require("youtrack.queries").get_queries,
	get_agiles = require("youtrack.agiles").get_agiles,
	get_issues = require("youtrack.issues").get_issues,
	get_issue = require("youtrack.issues").get_issue,
	reset_last_issue = require("youtrack.issues").reset_lasts,
	create_issue = require("youtrack.issues").create_issue,
	_ = {},
}

---@param config youtrack.Config
function M.setup(config)
	local c = require("youtrack.config").setup(config)

	local log = require("youtrack.log").setup({ level = c.log_level })

	require("youtrack.lib").setup({
		url = c.url,
		token = c.token,
		queries = c.queries,
		issues = {
			fields = c.issues.fields,
		},
		issue = {
			fields = c.issue.fields,
		},
	})

	log.debug("Plugin has been setup: %s", c)
end

return M
