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
			tags = {},
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
					flex = 1,
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
					flex = 2,
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
						line:append(node.text, "@function")
						line:append(" ")
						line:append(node.summary, "@string")

						for _, tag in ipairs(node.tags) do
							line:append(" ")
							line:append(("(%s)"):format(tag.name), "@tag")
						end

						for _, field in ipairs(node.fields) do
							line:append(" ")
							line:append("[", "@comment")
							line:append(field.name, "@constant")
							line:append(": ", "@comment")
							line:append(field.text)
							line:append("]", "@comment")
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
				{ flex = 1 },
				n.columns(
					{ flex = 1 },
					n.rows(
						{
							flex = 2,
						},
						n.paragraph({
							id = "issue_header",
							border_style = setup.config.ui.border,
							border_label = "Issue",
							lines = signal_issue.header,
						}),
						n.buffer({
							flex = 3,
							border_style = setup.config.ui.border,
							id = "issue_comments",
							buf = vim.api.nvim_create_buf(false, true),
							autoscroll = false,
							autofocus = false,
							filetype = "markdown",
							border_label = "Comments",
						}),
						n.buffer({
							id = "comment",
							flex = 2,
							buf = vim.api.nvim_create_buf(false, true),
							autoscroll = true,
							border_style = setup.config.ui.border,
							border_label = "Comment",
							filetype = "markdown",
						})
					),
					n.rows(
						{ flex = 4 },
						n.buffer({
							border_style = setup.config.ui.border,
							border_label = "Summary",
							size = 1,
							id = "issue_summary",
							buf = vim.api.nvim_create_buf(false, true),
							autoscroll = false,
							autofocus = false,
							filetype = "markdown",
						}),
						n.buffer({
							border_style = setup.config.ui.border,
							border_label = "Description",
							flex = 1,
							id = "issue_description",
							buf = vim.api.nvim_create_buf(false, true),
							autoscroll = false,
							autofocus = true,
							filetype = "markdown",
							-- border_label = ("Issue %s"):format(signal.selected_issue:get_value().text),
						})
					),
					n.rows(
						{ flex = 1 },
						n.paragraph({
							flex = 1,
							id = "issue_tags",
							border_style = setup.config.ui.border,
							border_label = "Tags",
							lines = signal_issue.tags,
						}),
						n.paragraph({
							flex = 2,
							id = "issue_fields",
							border_style = setup.config.ui.border,
							border_label = "Fields",
							lines = signal_issue.fields,
						})
					)
				),
				n.box(
					{
						direction = "row",
						flex = 0,
						border_style = setup.config.ui.border,
					},
					n.text_input({
						flex = 1,
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
					n.gap(1),
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

								local s = vim.fn.join(summary_content, "\n")
								local d = vim.fn.join(description_content, "\n")

								if
									s ~= signal_issue.issue:get_value().summary
									or d ~= signal_issue.issue:get_value().description
								then
									lib.update_issue({
										id = signal_issue.issue:get_value().id,
										summary = s,
										description = d,
									}, function(err, _)
										if err then
											log.print.error(err)

											return
										end

										log.info("Issue updated: %s", signal_issue.issue:get_value().text)

										signal_issue.should_refresh = true
									end)
								else
									log.debug("Nothing changed for the issue: %s", signal_issue.issue:get_value().text)
								end
							else
								log.debug("No need to update for the issue: %s", signal_issue.issue:get_value().text)
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
											"Command applied to issue: %s -> %s",
											signal_issue.issue:get_value().text,
											command:get_current_value()
										)

										utils.set_component_value(command, "")

										signal_issue.should_refresh = true
									end
								)
							else
								log.debug(
									"No command to be applied for the issue: %s",
									signal_issue.issue:get_value().text
								)
							end

							local comment = renderer:get_component_by_id("comment")
							if comment ~= nil and utils.get_component_buffer_content(comment)[1] ~= "" then
								lib.add_issue_comment({
									id = signal_issue.issue:get_value().id,
									comment = vim.fn.join(utils.get_component_buffer_content(comment), "\n"),
								}, function(err, _)
									if err then
										log.print.error(err)

										return
									end

									log.info("Comment applied to issue: %s", signal_issue.issue:get_value().text)

									utils.set_component_buffer_content(comment, "")

									signal_issue.should_refresh = true
								end)
							else
								log.debug(
									"No comment to be applied for the issue: %s",
									signal_issue.issue:get_value().text
								)
							end
						end,
					}),
					n.gap(1),
					n.button({
						label = "Refresh <C-r>",
						global_press_key = "<C-r>",
						autofocus = false,
						border_style = setup.config.ui.border,
						on_press = function()
							signal_issue.should_refresh = true
						end,
					}),
					n.gap(1),
					n.button({
						label = "Open <C-o>",
						global_press_key = "<C-o>",
						autofocus = false,
						border_style = setup.config.ui.border,
						on_press = function()
							vim.ui.open(("%s/issue/%s"):format(setup.config.url, signal_issue.issue:get_value().text))
						end,
					}),
					n.gap(1),
					n.button({
						label = "Close <C-x>",
						global_press_key = "<C-x>",
						autofocus = false,
						border_style = setup.config.ui.border,
						on_press = function()
							if signal.active:get_value() == "issue" then
								signal_issue.issue = nil
								signal_issues.issue = nil

								signal.active = "issues"

								return
							end

							renderer:close()
						end,
					})
				)
			)
		)
	)

	signal.active:observe(function(active)
		renderer:set_size(setup.config[active].size)
	end)

	signal.error:observe(function(err)
		if not err then
			return
		end

		local error = renderer:get_component_by_id("error")
		if error ~= nil then
			utils.set_component_buffer_content(error, err)
		end

		signal.active = "error"
	end)

	signal_issues.query:debounce(500):observe(function(query)
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

	signal_issues.issue:observe(function(issue)
		if issue == nil then
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
				local text = {
					n.text(("[%s]"):format(res.project.name), "@class"),
					n.text(" "),
					n.text(res.text, "@constant"),
				}

				signal_issue.header = {
					n.line(unpack(text)),
				}
			end

			local issue_summary = renderer:get_component_by_id("issue_summary")
			if issue_summary ~= nil then
				utils.set_component_buffer_content(issue_summary, res.summary, true)
			end

			local issue_tags = renderer:get_component_by_id("issue_tags")
			if issue_tags ~= nil then
				local text = {}

				for _, tag in ipairs(res.tags) do
					table.insert(text, n.text(("(%s)"):format(tag.name), "@tag"))
				end

				signal_issue.tags = vim.tbl_map(function(line)
					return n.line(line)
				end, text)
			end

			local issue_fields = renderer:get_component_by_id("issue_fields")
			if issue_fields ~= nil then
				local lines = {}

				for _, field in ipairs(res.fields) do
					table.insert(lines, {
						n.text("[", "@comment"),
						n.text(field.name, "@constant"),
						n.text(": "),
						n.text(field.text),
						n.text("]", "@comment"),
					})
				end

				signal_issue.fields = vim.tbl_map(function(line)
					return n.line(unpack(line))
				end, lines)
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
				for i, comment in ipairs(res.comments) do
					if i > 1 then
						table.insert(comments, "")
					end

					vim.list_extend(
						comments,
						vim.list_extend({
							("# %s - %s"):format(comment.author, comment.created_at),
							"",
						}, vim.split(comment.text, "\n"))
					)
				end

				utils.set_component_buffer_content(issue_comments, comments)
			end

			signal.active = "issue"
		end)
	end)

	signal_issue.should_refresh:observe(function(should_refresh)
		if should_refresh then
			log.debug("Should refresh the given issue: %s", signal_issue.issue:get_value().text)
			local issue = signal_issues.issue:get_value()
			signal_issues.issue = nil
			signal_issues.issue = issue
			signal_issue.should_refresh = nil
			log.info("Issue refreshed: %s", signal_issue.issue:get_value().text)
		end
	end)

	lib.get_saved_queries(nil, function(err, res)
		local queries = { { name = "Create a new query...", query = "" } }

		vim.list_extend(queries, setup.config.queries)

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

		signal_queries.queries = vim.tbl_map(function(query)
			return n.node(query)
		end, queries)

		renderer:render(body)
	end)
end

return M
