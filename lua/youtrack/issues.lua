local M = {
	_ = {
		state = nil,
	},
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local setup = require("youtrack.setup")

---@class youtrack.GetIssuesOptions
---@field toggle? boolean

---@param opts youtrack.GetIssuesOptions
function M.get_issues(opts)
	opts = opts or {}

	if not opts.toggle or not M._.state then
		M._.state = {}

		M._.state.signal_queries = n.create_signal({
			queries = vim.list_extend(
				vim.tbl_map(function(query)
					return n.node(query)
				end, setup.config.issues.queries),
				{ n.node({ name = "Create a new query...", query = "" }) }
			),
			query = nil,
		})

		M._.state.signal = n.create_signal({
			active = "issues",
			error = nil,
		})

		M._.state.signal_issues = n.create_signal({
			query = nil,
			issues = {},
			issue = nil,
		})

		M._.state.signal_issue = n.create_signal({
			issue = nil,
			should_refresh = nil,
		})
	end
	local signal = M._.state.signal
	local signal_queries = M._.state.signal_queries
	local signal_issues = M._.state.signal_issues
	local signal_issue = M._.state.signal_issue

	local is_tab_active = n.is_active_factory(signal.active)

	local renderer = n.create_renderer(vim.tbl_deep_extend("force", {}, setup.config.ui, {
		position = "50%",
		relative = "editor",
	}))
	renderer:add_mappings({
		{
			mode = { "n" },
			key = "q",
			handler = function()
				renderer:close()
			end,
		},
	})

	local body = n.tabs(
		{ active_tab = signal.active },
		n.columns(
			{ flex = 0 },
			n.button({
				border_style = setup.config.ui.border,
				label = "Issues",
				-- global_press_key = "<S-u>",
				is_active = is_tab_active("issues"),
				on_press = function()
					signal.active = "issues"
				end,
				hidden = signal_issues.query:negate(),
			}),
			n.gap(1),
			n.button({
				border_style = setup.config.ui.border,
				label = "Issue",
				-- global_press_key = "<S-u>",
				is_active = is_tab_active("issue"),
				on_press = function()
					signal.active = "issue"
				end,
				hidden = signal_issue.issue:negate(),
			})
		),
		n.tab(
			{ id = "error" },
			n.rows(
				{ flex = 1 },
				n.buffer({
					id = "error",
					border_style = setup.config.ui.border,
					flex = 1,
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					border_label = "Error",
				})
			)
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
					border_style = setup.config.ui.border,
					autofocus = true,
					autoresize = false,
					value = signal_issues.query,
					size = 1,
					border_label = "Query",
					placeholder = "Enter a youtrack query...",
					max_lines = 1,
					on_change = function(value, component)
						signal_issues.query = value
					end,
				}),
				n.tree({
					size = 12,
					border_label = "Select issue",
					border_style = setup.config.ui.border,
					-- hidden = signal_issues.issues:negate(),
					data = signal_issues.issues,
					on_select = function(node, component)
						signal_issues.issue = node
						component:get_tree():render()
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
					border_style = setup.config.ui.border,
					flex = 1,
					id = "issue",
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					autofocus = true,
					filetype = "markdown",
					-- border_label = ("Issue %s"):format(signal.selected_issue:get_value().idReadable),
				}),
				n.text_input({
					id = "command",
					border_style = setup.config.ui.border,
					border_label = "Command",
					autofocus = false,
					autoresize = false,
					size = 1,
					placeholder = "Enter a command to apply to issue...",
					value = "",
					max_lines = 1,
				}),
				n.text_input({
					id = "comment",
					border_style = setup.config.ui.border,
					border_label = "Comment",
					autofocus = false,
					autoresize = false,
					size = 1,
					value = "",
					placeholder = "Enter a comment to apply to issue...",
				}),
				n.box(
					{
						direction = "row",
						flex = 0,
						border_style = setup.config.ui.border,
					},
					n.button({
						label = "Send",
						border_style = setup.config.ui.border,
						on_press = function()
							local command = renderer:get_component_by_id("command")
							if command and command:get_current_value() ~= nil and command:get_current_value() ~= "" then
								lib.apply_issue_command(
									{ id = signal_issue.issue:get_value().id, query = command:get_current_value() },
									function(err, res)
										if err then
											log.print.error(err)

											return
										end

										log.info(
											"Command applied to issue: %s -> %s with %s",
											signal_issue.issue:get_value().idReadable,
											command:get_current_value(),
											res
										)

										command:set_current_value("")
										command:redraw()

										signal_issue.should_refresh = true
									end
								)
							else
								log.debug(
									"No command to be applied for the issue: %s",
									signal_issue.issue:get_value().idReadable
								)
							end

							local comment = renderer:get_component_by_id("comment")
							if comment and comment:get_current_value() ~= nil and comment:get_current_value() ~= "" then
								lib.add_issue_comment(
									{ id = signal_issue.issue:get_value().id, comment = comment:get_current_value() },
									function(err, res)
										if err then
											log.print.error(err)

											return
										end

										log.info(
											"Comment applied to issue: %s -> %s with %s",
											signal_issue.issue:get_value().idReadable,
											comment:get_current_value(),
											res
										)

										comment:set_current_value("")
										comment:redraw()

										signal_issue.should_refresh = true
									end
								)
							else
								log.debug(
									"No comment to be applied for the issue: %s",
									signal_issue.issue:get_value().idReadable
								)
							end
						end,
					}),
					n.gap(1),
					n.button({
						label = "View",
						border_style = setup.config.ui.border,
						on_press = function()
							vim.ui.open(
								("%s/issue/%s"):format(setup.config.url, signal_issue.issue:get_value().idReadable)
							)
						end,
					}),
					n.gap(1),
					n.button({
						label = "Close",
						border_style = setup.config.ui.border,
						on_press = function()
							signal_issues.issue = nil

							signal.active = "issues"
						end,
					})
				)
			)
		)
	)

	signal.active:observe(function(active)
		if active == "issues" then
			renderer:set_size({ height = 16 })
		elseif active == "issue" then
			renderer:set_size({ height = 32 })
		end
		-- renderer:redraw()
	end)

	signal.error:skip(1):observe(function(err)
		if not err then
			return
		end

		local component = renderer:get_component_by_id("error")
		if component ~= nil then
			component:modify_buffer_content(function()
				vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, vim.split(err, "\n"))
			end)
		end

		signal.active = "error"
	end)

	signal_queries.query:skip(1):observe(function(query)
		signal_issues.query = query.query
		renderer:close()
		renderer:render(body)
	end)

	signal_issues.query:skip(1):debounce(500):observe(function(query)
		if query == nil then
			return
		end

		local component = renderer:get_component_by_id("query")
		if component ~= nil then
			component:set_border_text("bottom", "running...", "right")
		end

		lib.get_issues({ query = query }, function(err, res)
			if err then
				signal_issues.issues = {}
				signal.error = err

				return
			end

			if #res == 0 then
				signal_issues.issues = {}
				if component ~= nil then
					component:set_border_text("bottom", "no match", "right")
				end

				return
			end

			local issues = vim.tbl_map(function(issue)
				return n.node(issue)
			end, res or {})

			signal_issues.issues = issues

			if component ~= nil then
				component:set_border_text("bottom", ("matches: %d"):format(#issues), "right")
			end
		end)
	end)

	signal_issues.issue:skip(1):observe(function(issue)
		if not issue then
			return
		end

		lib.get_issue({ id = issue.id }, function(err, res)
			if err then
				signal.error = err

				return
			end

			signal_issue.issue = res

			local component = renderer:get_component_by_id("issue")
			if component ~= nil then
				local details = {}

				vim.list_extend(details, {
					("# [%s] %s - %s"):format(res.project.name, res.idReadable, res.summary),
				})

				local fields = {}
				for _, field in ipairs(res.customFields) do
					if field["$type"] == "PeriodIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-PeriodIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.presentation))
					elseif field["$type"] == "DateIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-DateIssueCustomField.html
						table.insert(
							fields,
							("[ %s: %s ]"):format(field.name, os.date("%Y%m%dT%H:%M:%S", field.value / 1000))
						)
					elseif field["$type"] == "SimpleIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-DateIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value))
					elseif field["$type"] == "StateIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-StateIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					-- elseif field["$type"] == "SingleBuildIssueCustomField" and type(field.value.name) ~= "userdata" then
					-- 	-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleBuildIssueCustomField.html
					-- 	table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "SingleUserIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleUserIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "SingleGroupIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleGroupIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "SingleVersionIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleVersionIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "SingleOwnedIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleOwnedIssueCustomField.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "SingleEnumIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-EnumBundleElement.html
						table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
					elseif field["$type"] == "StateMachineIssueCustomField" and type(field.value) ~= "userdata" then
						-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-StateMachineIssueCustomField.html
						-- table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
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

				if type(res.comments) == "table" and #res.comments > 0 then
					vim.list_extend(details, { "", "## Comments" })

					table.sort(res.comments, function(a, b)
						return a.created > b.created
					end)

					for _, comment in ipairs(res.comments) do
						vim.list_extend(
							details,
							vim.list_extend({
								"",
								("### %s - %s"):format(
									comment.author.fullName,
									os.date("%Y%m%dT%H:%M:%S", comment.created / 1000)
								),
								"",
							}, vim.split(comment.text, "\n"))
						)
					end
				end

				component:modify_buffer_content(function()
					vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, details)
				end)
			end

			signal.active = "issue"
		end)
	end)

	signal_issue.should_refresh:skip(1):observe(function(should_refresh)
		if should_refresh then
			log.debug("Should refresh the given issue: %s", signal_issue.issue:get_value().idReadable)
			local issue = signal_issues.issue:get_value()
			signal_issues.issue = nil
			signal_issues.issue = issue
			signal_issue.should_refresh = nil
			renderer:redraw()
		end
	end)

	local prebody = n.rows(
		{ flex = 1 },
		n.tree({
			autofocus = true,
			size = 16,
			border_label = "Select query",
			border_style = setup.config.ui.border,
			data = signal_queries.queries,
			on_select = function(node, component)
				signal_queries.query = node
			end,
			prepare_node = function(node, line, component)
				line:append(node.name, "@class")

				return line
			end,
		})
	)

	if not opts.toggle or not signal_issues.query:get_value() then
		renderer:render(prebody)
	else
		renderer:render(body)
	end
end

return M
