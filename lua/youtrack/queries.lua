local M = {
	_ = require("youtrack")._,
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local config = require("youtrack.config")

---@return nil
function M.get_queries()
	local c = config.read()

	lib.get_saved_queries(nil, function(e, r)
		local queries = { { name = "Create a new query...", query = "" } }

		vim.list_extend(queries, c.queries)

		if e then
			log.p.error(e)
		else
			vim.list_extend(
				queries,
				vim.tbl_map(function(query)
					return n.node(query)
				end, r or {})
			)
		end

		vim.ui.select(queries, {
			prompt = "Select query",
			format_item = function(item)
				return ("%s [%s]"):format(item.name, item.query)
			end,
		}, function(query)
			if query == nil then
				return
			end

			require("youtrack.issues").get_issues({ query = query.query })
		end)
	end)
end

return M
