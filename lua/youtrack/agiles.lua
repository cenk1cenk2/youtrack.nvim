local M = {}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local config = require("youtrack.config")

---@class youtrack.GetAgilesOptions

---@param opts? youtrack.GetAgilesOptions
function M.get_agiles(opts)
	opts = opts or {}

	local c = config.read()

	lib.get_agiles(nil, function(err, agiles)
		if err then
			log.p.error(err)

			return
		end

		vim.ui.select(agiles, {
			prompt = "Select Agile",
			format_item = function(item)
				return item.name
			end,
		}, function(agile)
			if not agile then
				return
			end

			vim.ui.open(("%s/agiles/%s"):format(c.url, agile.id))
		end)
	end)
end

return M
