local M = {}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")

---@class youtrack.Config
---@field url string The hostname of the instance

---@param config youtrack.Config
function M.setup(config)
	log.setup()
	lib.setup(config)
end

function M.test_issues(opts)
	lib.get_issues(opts, function(issues)
		vim.print(vim.inspect(issues))
	end)
end

function M.get_issues(opts)
	opts = vim.tbl_extend("force", { query = "" }, opts or {})
	local signal = n.create_signal({
		query = opts.query,
		results = {},
		selected = nil,
	})

	-- local subscription = signal:observe(function(prev, curr) end)

	local body = n.rows(
		{ flex = 1 },
		--- text input for query
		n.text_input({
			autofocus = true,
			autoresize = true,
			size = 2,
			value = signal.query,
			border_label = "Query",
			placeholder = "Enter a youtrack query...",
			max_lines = 1,
			on_change = function(value, component)
				signal.query = value

				local ok, issues = pcall(lib.get_issues, { query = value })

				if not ok then
					signal.issues = {}

					return
				end

				-- vim.notify(vim.inspect(issues))
				signal.issues = vim.tbl_map(function(issue)
					return n.node(issue)
				end, issues)

				component:modify_buffer_content(function()
					component:set_border_text("bottom", "Length: " .. #signal.issues, "right")
				end)
			end,
			on_mount = function(component)
				local value = signal.query:get_value()

				-- component:set_border_text("bottom", "Length: " .. #signal.issues, "right")
			end,
		}),
		n.tree({
			hidden = #signal.issues == 0,
			border_label = "Select issue",
			selected = signal.selected,
			data = signal.issues,
			on_select = function(node, component)
				local tree = component:get_tree()
				signal.selected = node
				tree:render()
			end,
			prepare_node = function(node, line, component)
				line:append(node.summary)

				return line
			end,
		})
	)

	local renderer = M.get_renderer(body)
	renderer:add_mappings({
		{
			mode = { "n" },
			from = "q",
			to = function()
				renderer:close()
			end,
		},
	})

	-- renderer:on_unmount(function()
	-- 	subscription:unsubscribe()
	-- end)

	renderer:render(body)
end

function M.get_renderer(body)
	local renderer = n.create_renderer({
		width = 80,
		height = 40,
		relative = "editor",
	})

	return renderer
end

return M
