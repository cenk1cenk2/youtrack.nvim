local M = {
	_ = {
		history = {},
	},
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local config = require("youtrack.config")

---@class youtrack.GetIssuesOptions
---@field query? string
---@field toggle? boolean

---@param opts youtrack.GetIssuesOptions
function M.get_issues(opts)
	opts = vim.tbl_extend("force", { query = "for: me #Unresolved" }, opts or {})

	local signal = n.create_signal({
		active = "issues",
	})
	local issues_signal = n.create_signal({
		query = opts.query,
		has_issues = false,
		error_issues = false,
		issues = {},
		issue = nil,
	})
	local issue_signal = n.create_signal({
		issue = nil,
	})

	local is_tab_active = n.is_active_factory(signal.active)

	local renderer = n.create_renderer({
		width = 120,
		position = "50%",
		relative = "editor",
		keymap = {
			close = "<Esc>",
			focus_next = "<Tab>",
			focus_prev = "<S-Tab>",
			focus_left = "<Left>",
			focus_right = "<Right>",
			focus_up = "<Up>",
			focus_down = "<Down>",
		},
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

	signal.active:observe(function(active)
		if active == "issues" then
			renderer:set_size({ height = 16 })
		elseif active == "issue" then
			renderer:set_size({ height = 32 })
			renderer:redraw()
		end
	end)

	issues_signal.query:debounce(500):observe(function(query)
		local component_query = renderer:get_component_by_id("query")
		if component_query ~= nil then
			component_query:set_border_text("bottom", "running...", "right")
		end

		lib.get_issues({ query = query }, function(err, res)
			if err then
				issues_signal.issues = {}
				issues_signal.has_issues = false
				issues_signal.error_issues = true

				if component_query ~= nil then
					component_query:set_border_text("bottom", "error", "right")
				end

				local component_error = renderer:get_component_by_id("error")
				if component_error ~= nil then
					vim.api.nvim_set_option_value("modifiable", true, { buf = component_error.bufnr })
					vim.api.nvim_buf_set_lines(component_error.bufnr, 0, -1, false, vim.split(err, "\n"))
					vim.api.nvim_set_option_value("modifiable", false, { buf = component_error.bufnr })
				end
			end

			issues_signal.issues = vim.tbl_map(function(issue)
				return n.node(issue)
			end, res or {})
			issues_signal.has_issues = true
			issues_signal.error_issues = nil

			if component_query ~= nil then
				component_query:set_border_text(
					"bottom",
					("matches: %d"):format(#issues_signal.issues:get_value()),
					"right"
				)
			end
		end)
	end)

	issues_signal.issue:observe(function(issue)
		if issue == nil then
			issue_signal.issue = nil

			return
		end

		M._.history.issue = issue

		lib.get_issue({ id = issue.id }, function(err, res)
			if err then
				log.print.error(err)

				return
			end

			issue_signal.issue = res

			signal.active = "issue"

			local component_issue = renderer:get_component_by_id("issue")
			if component_issue ~= nil then
				local details = {}

				vim.list_extend(details, {
					("# [%s] %s - %s"):format(res.project.name, res.idReadable, res.summary),
				})

				local fields = {}
				for _, field in ipairs(res.customFields) do
					if type(field.value) == "table" and field.value.name ~= nil then
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif type(field.value) == "string" and field.value ~= nil then
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value))
					elseif type(field.value) == "number" then
						table.insert(fields, ("[ %s: %d ]"):format(field.name, field.value))
					end
				end
				if #fields > 0 then
					vim.list_extend(details, { "", vim.fn.join(fields, " | ") })
				end

				if type(res.description) == "string" then
					local description = vim.split(res.description or "", "\n")
					if #description > 0 then
						vim.list_extend(details, { "", "## Description", "" })
						vim.list_extend(details, description)
					end
				end

				if #res.comments > 0 then
					vim.list_extend(details, { "", "## Comments" })

					for _, comment in ipairs(res.comments) do
						vim.list_extend(
							details,
							vim.list_extend({
								"",
								("### %s - %s"):format(
									comment.author.fullName,
									os.date("%Y%m%dT%H%M%S", comment.created)
								),
								"",
							}, vim.split(comment.text, "\n"))
						)
					end
				end

				vim.api.nvim_set_option_value("modifiable", true, { buf = component_issue.bufnr })
				vim.api.nvim_buf_set_lines(component_issue.bufnr, 0, -1, false, details)
				vim.api.nvim_set_option_value("modifiable", false, { buf = component_issue.bufnr })
			end
		end)
	end)

	local body = n.tabs(
		{ active_tab = signal.active },
		n.columns(
			{ flex = 0 },
			n.button({
				border_style = config.ui.border,
				label = "Issues",
				-- global_press_key = "<S-u>",
				is_active = is_tab_active("issues"),
				on_press = function()
					signal.active = "issues"
				end,
			}),
			n.gap(1),
			n.button({
				border_style = config.ui.border,
				label = "Issue",
				-- global_press_key = "<S-u>",
				is_active = is_tab_active("issue"),
				on_press = function()
					signal.active = "issue"
				end,
				hidden = issues_signal.issue:negate(),
			})
		),
		n.tab(
			{
				id = "issues",
			},
			n.rows(
				{ flex = 1 },
				--- text input for query
				n.text_input({
					id = "query",
					border_style = config.ui.border,
					autofocus = true,
					autoresize = false,
					size = 2,
					value = issues_signal.query,
					border_label = "Query",
					placeholder = "Enter a youtrack query...",
					max_lines = 1,
					on_change = function(value, component)
						issues_signal.query = value
					end,
				}),
				n.buffer({
					id = "error",
					border_style = config.ui.border,
					flex = 1,
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					border_label = "Error",
					hidden = issues_signal.error_issues:negate(),
				}),
				n.tree({
					size = 10,
					border_label = "Select issue",
					border_style = config.ui.border,
					data = issues_signal.issues,
					on_select = function(node, component)
						local tree = component:get_tree()
						issues_signal.issue = node
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
		n.tab(
			{
				id = "issue",
			},
			n.rows(
				{
					flex = 1,
				},
				n.buffer({
					border_style = config.ui.border,
					flex = 1,
					id = "issue",
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					filetype = "markdown",
					-- border_label = ("Issue %s"):format(signal.selected_issue:get_value().idReadable),
				}),
				n.text_input({
					id = "command",
					border_style = config.ui.border,
					border_label = "Command",
					autofocus = true,
					autoresize = false,
					size = 1,
					placeholder = "Enter a command to apply to issue...",
					max_lines = 1,
				}),
				n.text_input({
					id = "comment",
					border_style = config.ui.border,
					border_label = "Comment",
					autofocus = false,
					autoresize = false,
					size = 1,
					placeholder = "Enter a comment to apply to issue...",
				}),
				n.columns(
					{
						flex = 0,
					},
					n.button({
						label = "Send",
						border_style = config.ui.border,
						on_press = function()
							local command = renderer:get_component_by_id("command")

							if command == nil then
								log.error("Command component not found.")

								return
							end

							if command:get_current_value() ~= nil and command:get_current_value() ~= "" then
								lib.apply_issue_command(
									{ id = issue_signal.issue:get_value().id, query = command:get_current_value() },
									function(err, res)
										if err then
											log.print.error(err)

											return
										end

										command:set_current_value("")

										log.info(
											"Command applied to issue: %s -> %s with %s",
											issue_signal.issue:get_value().idReadable,
											command:get_current_value(),
											res
										)
									end
								)
							end
						end,
					}),
					n.gap(1),
					n.button({
						label = "View",
						border_style = config.ui.border,
						on_press = function()
							vim.notify(("%s/issue/%s"):format(config.url, issue_signal.issue:get_value().idReadable))
							-- vim.ui.open(("%s/issue/%s"):format(config.url, issue_signal.issue:get_value().idReadable))
						end,
					}),
					n.gap(1),
					n.button({
						label = "Close",
						border_style = config.ui.border,
						on_press = function()
							signal.active = "issues"
							issues_signal.issue = nil
						end,
					})
				)
			)
		)
	)

	renderer:render(body)

	if opts.toggle then
		issues_signal.issue = M._.history.issue
	end
end

return M
