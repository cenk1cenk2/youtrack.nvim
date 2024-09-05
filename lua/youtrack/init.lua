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
	lib.get_issues(opts, function(error, issues)
		vim.print(vim.inspect(error))
		vim.print(vim.inspect(issues))
	end)
end

function M.get_issues(opts)
	opts = vim.tbl_extend("force", { query = "for: me #Unresolved" }, opts or {})
	local signal = n.create_signal({
		-- general view
		component_query = nil,
		query = opts.query,
		has_issues = false,
		error_issues = false,
		issues = {},
		issue = nil,
		-- detail view
		selected_issue = false,
		issue_detail = nil,
	})

	local renderer = n.create_renderer({
		width = 120,
		height = 10,
		position = "50%",
		relative = "editor",
	})
	renderer:add_mappings({
		{
			mode = { "n" },
			key = "q",
			handler = function()
				renderer:close()
			end,
		},
	})

	signal.query:debounce(500):observe(function(query)
		local component_query = signal.component_query:get_value()
		if component_query ~= nil then
			component_query:set_border_text("bottom", "running...", "right")
		end

		lib.get_issues({ query = query }, function(err, issues)
			if err then
				signal.issues = {}
				signal.has_issues = false
				signal.error_issues = true

				if component_query ~= nil then
					component_query:set_border_text("bottom", "error", "right")
				end

				local display_error_issues = renderer:get_component_by_id("error_issues")
				if display_error_issues ~= nil then
					vim.api.nvim_set_option_value("modifiable", true, { buf = display_error_issues.bufnr })
					vim.api.nvim_buf_set_lines(display_error_issues.bufnr, 0, -1, false, vim.split(err, "\n"))
					vim.api.nvim_set_option_value("modifiable", false, { buf = display_error_issues.bufnr })
				end
			end

			signal.issues = vim.tbl_map(function(issue)
				return n.node(issue)
			end, issues or {})
			signal.has_issues = true
			signal.error_issues = nil

			if component_query ~= nil then
				component_query:set_border_text("bottom", ("matches: %d"):format(#signal.issues:get_value()), "right")
			end
		end)
	end)

	signal.issue:observe(function(issue)
		if issue == nil then
			return
		end

		lib.get_issue({ id = issue.id }, function(err, issue_detail)
			if err then
				log.print.error(err)

				return
			end

			signal.issue_detail = issue_detail

			local display_issue_detail = renderer:get_component_by_id("issue_detail")
			if display_issue_detail ~= nil then
				local details = {}

				vim.list_extend(details, {
					("# [%s] %s - %s"):format(issue_detail.project.name, issue_detail.idReadable, issue_detail.summary),
					"",
					"## Description",
				})

				vim.list_extend(details, vim.split(issue_detail.description, "\n"))

				vim.api.nvim_set_option_value("modifiable", true, { buf = display_issue_detail.bufnr })
				vim.api.nvim_buf_set_lines(display_issue_detail.bufnr, 0, -1, false, details)
				vim.api.nvim_set_option_value("modifiable", false, { buf = display_issue_detail.bufnr })
			end
		end)
	end)

	local body = n.rows(
		{ flex = 0 },
		-- issue select view
		n.rows(
			{ flex = 0, hidden = signal.selected_issue },
			--- text input for query
			n.text_input({
				autofocus = true,
				autoresize = false,
				size = 2,
				value = signal.query,
				border_label = "Query",
				placeholder = "Enter a youtrack query...",
				max_lines = 1,
				on_change = function(value, component)
					signal.query = value
				end,
				on_mount = function(component)
					signal.component_query = component
				end,
			}),
			n.buffer({
				flex = 1,
				id = "display_error_issues",
				buf = vim.api.nvim_create_buf(false, true),
				autoscroll = false,
				border_label = "Error",
				hidden = signal.error_issues:negate(),
			}),
			n.rows(
				{
					flex = 0,
					hidden = signal.has_issues:negate(),
				},
				n.tree({
					size = 10,
					border_label = "Select issue",
					data = signal.issues,
					on_select = function(node, component)
						local tree = component:get_tree()
						signal.issue = node
						signal.selected_issue = true
						tree:render()
					end,
					prepare_node = function(node, line, component)
						line:append(("[%s]"):format(node.project.name), "@class")
						line:append((" %s"):format(node.idReadable), "@constant")
						line:append((" %s"):format(node.summary, "@string"))

						return line
					end,
				})
			)
		),
		-- issue detail view
		n.rows(
			{
				flex = 0,
				hidden = signal.selected_issue:negate(),
			},
			n.buffer({
				flex = 1,
				id = "issue_detail",
				buf = vim.api.nvim_create_buf(false, true),
				autoscroll = false,
				filetype = "markdown",
				-- border_label = ("Issue %s"):format(signal.selected_issue:get_value().idReadable),
			}),
			n.text_input({
				autofocus = true,
				autoresize = false,
				size = 1,
				border_label = "issue #%s",
				placeholder = "Enter a command to apply to issue #%s...",
				max_lines = 1,
				on_change = function(value, component)
					-- signal.query = value
				end,
				on_mount = function(component)
					-- signal.component_query = component
				end,
			})
		)
	)

	-- renderer:on_unmount(function()
	-- 	subscription:unsubscribe()
	-- end)

	renderer:render(body)
end

return M
