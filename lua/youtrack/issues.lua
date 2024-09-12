local M = {
	_ = {
		state = nil,
	},
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local setup = require("youtrack.setup")
local utils = require("youtrack.utils")

---@class youtrack.GetIssuesOptions
---@field toggle? boolean

---@param opts youtrack.GetIssuesOptions
function M.get_issues(opts)
	opts = opts or {}

	if not opts.toggle or not M._.state then
		M._.state = {}

		M._.state.signal = n.create_signal({
			active = "issues",
			error = nil,
		})

		M._.state.signal_queries = n.create_signal({
			queries = nil,
		})

		M._.state.signal_issues = n.create_signal({
			query = "",
			issues = {},
			issue = nil,
		})

		M._.state.signal_issue = n.create_signal({
			issue = nil,
			should_refresh = nil,
			header = {},
			fields = {},
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
				label = "Issues",
				autofocus = false,
				border_style = setup.config.ui.border,
				-- global_press_key = "<S-u>",
				is_active = is_tab_active("issues"),
				on_press = function()
					signal.active = "issues"
				end,
				hidden = signal_issues.query:negate(),
			}),
			n.gap(1),
			n.button({
				label = "Issue",
				autofocus = false,
				border_style = setup.config.ui.border,
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
				n.tree({
					autofocus = true,
					size = 4,
					border_label = "Select query",
					border_style = setup.config.ui.border,
					data = signal_queries.queries,
					on_select = function(node, _)
						signal_issues.query = node.query

						local query = renderer:get_component_by_id("query")
						if query ~= nil then
							utils.set_component_value(query, node.query)
						end
					end,
					prepare_node = function(node, line, _)
						line:append(node.name, "@class")
						line:append(" ")
						line:append(node.query, "@comment")

						return line
					end,
				}),
				--- text input for query
				n.text_input({
					id = "query",
					border_style = setup.config.ui.border,
					autofocus = false,
					autoresize = false,
					size = 1,
					border_label = "Query",
					placeholder = "Enter a youtrack query...",
					value = signal_issues.query,
					max_lines = 1,
					on_mount = function(component)
						utils.set_component_value(component)
					end,
					on_change = function(value, _)
						signal_issues.query = value
					end,
				}),
				n.tree({
					flex = 1,
					border_label = "Select issue",
					border_style = setup.config.ui.border,
					-- hidden = signal_issues.issues:negate(),
					data = signal_issues.issues,
					on_select = function(node, component)
						signal_issues.issue = node
						component:get_tree():render()
					end,
					prepare_node = function(node, line, _)
						line:append(("[%s]"):format(node.project.name), "@class")
						line:append(" ")
						line:append(node.idReadable, "@constant")
						line:append(" ")
						line:append(node.summary, "@string")

						local fields = utils.process_fields(node)
						if #fields > 0 then
							for _, field in ipairs(fields) do
								line:append(" ")
								line:append(("[%s: %s]"):format(field.key, tostring(field.value)), "@comment")
							end
						end

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
				n.paragraph({
					id = "issue_header",
					border_style = setup.config.ui.border,
					border_label = "Issue",
					lines = signal_issue.header,
				}),
				n.buffer({
					border_style = setup.config.ui.border,
					size = 1,
					id = "issue_summary",
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					autofocus = false,
					filetype = "markdown",
					border_label = "Description",
				}),
				n.paragraph({
					id = "issue_fields",
					border_style = setup.config.ui.border,
					border_label = "Fields",
					lines = signal_issue.fields,
				}),
				n.buffer({
					border_style = setup.config.ui.border,
					flex = 2,
					id = "issue_description",
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					autofocus = true,
					filetype = "markdown",
					-- border_label = ("Issue %s"):format(signal.selected_issue:get_value().idReadable),
				}),
				n.buffer({
					flex = 1,
					border_style = setup.config.ui.border,
					id = "issue_comments",
					buf = vim.api.nvim_create_buf(false, true),
					autoscroll = false,
					autofocus = false,
					filetype = "markdown",
					border_label = "Comments",
				}),
				n.text_input({
					id = "command",
					border_style = setup.config.ui.border,
					border_label = "Command",
					value = "",
					autofocus = false,
					autoresize = false,
					size = 1,
					placeholder = "Enter a command to apply to issue...",
					max_lines = 1,
					on_mount = function(component)
						utils.set_component_value(component)
					end,
				}),
				n.text_input({
					id = "comment",
					border_style = setup.config.ui.border,
					border_label = "Comment",
					value = "",
					autofocus = false,
					autoresize = false,
					size = 1,
					placeholder = "Enter a comment to apply to issue...",
					on_mount = function(component)
						utils.set_component_value(component)
					end,
				}),
				n.box(
					{
						direction = "row",
						flex = 0,
						border_style = setup.config.ui.border,
					},
					n.button({
						label = "Save <C-s>",
						border_style = setup.config.ui.border,
						autofocus = false,
						global_press_key = "<C-s>",
						on_press = function()
							local description = renderer:get_component_by_id("issue_description")
							local summary = renderer:get_component_by_id("issue_summary")
							if description ~= nil and summary ~= nil then
								local summary_content = utils.get_component_buffer_content(summary)
								local description_content = utils.get_component_buffer_content(description)

								lib.update_issue({
									id = signal_issue.issue:get_value().id,
									summary = vim.fn.join(summary_content, "\n"),
									description = vim.fn.join(description_content, "\n"),
								}, function(err, _)
									if err then
										log.print.error(err)

										return
									end

									log.info("Issue updated: %s", signal_issue.issue:get_value().idReadable)

									signal_issue.should_refresh = true
								end)
							else
								log.debug(
									"No need to update for the issue: %s",
									signal_issue.issue:get_value().idReadable
								)
							end

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

										utils.set_component_value(command, "")

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

										utils.set_component_value(comment, "")

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
						label = "Open <C-o>",
						global_press_key = "<C-o>",
						autofocus = false,
						border_style = setup.config.ui.border,
						on_press = function()
							vim.ui.open(
								("%s/issue/%s"):format(setup.config.url, signal_issue.issue:get_value().idReadable)
							)
						end,
					}),
					n.gap(1),
					n.button({
						label = "Close <C-x>",
						global_press_key = "<C-x>",
						autofocus = false,
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
		renderer:set_size(setup.config[active].size)
	end)

	signal.error:skip(1):observe(function(err)
		if not err then
			return
		end

		local error = renderer:get_component_by_id("error")
		if error ~= nil then
			utils.set_component_buffer_content(error, err)
		end

		signal.active = "error"
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

			signal_issues.issues = vim.tbl_map(function(issue)
				return n.node(issue)
			end, res or {})

			if component ~= nil then
				component:set_border_text("bottom", ("matches: %d"):format(#(res or {})), "right")
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

			local issue_header = renderer:get_component_by_id("issue_header")
			if issue_header ~= nil then
				signal_issue.header = {
					n.line(
						n.text(("[%s]"):format(res.project.name), "@class"),
						n.text(" "),
						n.text(res.idReadable, "@constant")
					),
				}
			end

			local issue_summary = renderer:get_component_by_id("issue_summary")
			if issue_summary ~= nil then
				utils.set_component_buffer_content(issue_summary, res.summary, true)
			end

			local issue_fields = renderer:get_component_by_id("issue_fields")

			if issue_fields ~= nil then
				local fields = utils.process_fields(res)

				local text = {}

				for i, field in ipairs(fields) do
					if i > 1 then
						table.insert(text, n.text(" "))
					end
					table.insert(text, n.text(("[ %s: %s ]"):format(field.key, tostring(field.value))))
				end

				signal_issue.fields = { n.line(unpack(text)) }
			end

			local issue_description = renderer:get_component_by_id("issue_description")
			if issue_description ~= nil then
				local description = {}

				if type(res.description) == "string" then
					local d = vim.split(res.description or "", "\n")
					if #d > 0 then
						vim.list_extend(description, d)
					end
				end

				utils.set_component_buffer_content(issue_description, description, true)
			end

			local issue_comments = renderer:get_component_by_id("issue_comments")
			if issue_comments ~= nil then
				local comments = {}
				if type(res.comments) == "table" and #res.comments > 0 then
					table.sort(res.comments, function(a, b)
						return a.created > b.created
					end)

					for i, comment in ipairs(res.comments) do
						if i > 1 then
							table.insert(comments, "")
						end

						vim.list_extend(
							comments,
							vim.list_extend({
								("### %s - %s"):format(
									comment.author.fullName,
									os.date("%Y%m%dT%H:%M:%S", comment.created / 1000)
								),
								"",
							}, vim.split(comment.text, "\n"))
						)
					end
				end

				utils.set_component_buffer_content(issue_comments, comments)
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
		end
	end)

	lib.get_saved_queries(nil, function(err, res)
		local queries = { { name = "Create a new query...", query = "" } }

		if err then
			log.print.error(err)
		else
			vim.list_extend(
				queries,
				vim.tbl_map(function(query)
					return n.node(query)
				end, res or {})
			)
		end

		vim.list_extend(queries, setup.config.queries)

		signal_queries.queries = vim.tbl_map(function(query)
			return n.node(query)
		end, queries)

		renderer:render(body)
	end)
end

return M
