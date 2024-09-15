local M = {
	_ = {},
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local config = require("youtrack.config")
local utils = require("youtrack.utils")

---@class youtrack.GetIssuesOptions
---@field issue? table For passing in from other components to see the issue detail.

---@param opts? youtrack.GetIssuesOptions
function M.get_issues(opts)
	opts = opts or {}

	local c = config.read()

	if M._.renderer ~= nil then
		M._.renderer:close()

		return
	end

	local ui = vim.tbl_deep_extend("force", {}, utils.calculate_ui(c.ui), {
		position = "50%",
		relative = "editor",
	})
	local renderer = n.create_renderer(ui)
	local augroup = "youtrack_issues"

	renderer:add_mappings({
		{
			mode = { "n" },
			key = "q",
			handler = function()
				renderer:close()
			end,
		},
	})

	renderer:on_mount(function()
		M._.renderer = renderer

		utils.attach_resize(augroup, renderer, ui)

		if c.ui.autoclose then
			utils.attach_autoclose(renderer)
		end
	end)

	renderer:on_unmount(function()
		M._.renderer = nil

		pcall(vim.api.nvim_del_augroup_by_name, augroup)
	end)

	local signal = n.create_signal({
		active = "issues",
		error = nil,
	})

	local signal_queries = n.create_signal({
		queries = nil,
	})

	local signal_issues = n.create_signal({
		query = "",
		issues = {},
		issue = nil,
	})

	local signal_issue = n.create_signal({
		issue = nil,
		should_refresh = nil,
		header = {},
		fields = {},
		tags = {},
		command = "",
	})

	if opts.issue then
		signal.active = "issue"
		signal_issues.issue = opts.issue
	end

	local body = n.tabs(
		{ active_tab = signal.active },
		n.tab(
			{ id = "error" },
			n.rows(
				{ flex = 1 },
				n.buffer({
					id = "error",
					border_style = c.ui.border,
					flex = 1,
					buf = utils.create_buffer(true, false),
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
					border_style = c.ui.border,
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
					border_style = c.ui.border,
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
					border_style = c.ui.border,
					-- hidden = signal_issues.issues:negate(),
					data = signal_issues.issues,
					on_select = function(node, component)
						signal_issues.issue = node
						component:get_tree():render()
					end,
					prepare_node = function(node, line, _)
						line:append(("[%s]"):format(node.project.text), "@class")
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
							line:append("[", "@constant")
							line:append(field.name, "@constant")
							line:append(": ", "@comment")
							line:append(field.text)
							line:append("]", "@constant")
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
					{ flex = 0 },
					n.buffer({
						border_style = c.ui.border,
						border_label = "Summary",
						flex = 4,
						size = 1,
						id = "issue_summary",
						buf = utils.create_buffer(false, true),
						autoscroll = false,
						autofocus = false,
						filetype = "markdown",
					}),
					n.paragraph({
						id = "issue_header",
						border_style = c.ui.border,
						align = "center",
						is_focusable = false,
						flex = 3,
						size = 1,
						border_label = "Issue",
						lines = signal_issue.header,
					})
				),
				n.columns(
					{ flex = 1 },
					n.rows(
						{ flex = 4 },
						n.buffer({
							border_style = c.ui.border,
							border_label = "Description",
							flex = 1,
							id = "issue_description",
							buf = utils.create_buffer(false, true),
							autoscroll = false,
							autofocus = false,
							filetype = "markdown",
						})
					),
					n.rows(
						{
							flex = 2,
						},
						n.buffer({
							flex = 2,
							border_style = c.ui.border,
							id = "issue_comments",
							buf = utils.create_buffer(false, false),
							autoscroll = false,
							autofocus = false,
							filetype = "markdown",
							border_label = "Comments",
						}),
						n.buffer({
							id = "comment",
							flex = 1,
							buf = utils.create_buffer(false, true),
							autoscroll = true,
							border_style = c.ui.border,
							border_label = "Comment",
							filetype = "markdown",
						})
					),
					n.rows(
						{ flex = 1 },
						n.paragraph({
							flex = 2,
							id = "issue_fields",
							is_focusable = false,
							align = "center",
							border_style = c.ui.border,
							border_label = "Fields",
							lines = signal_issue.fields,
						}),
						n.paragraph({
							flex = 1,
							id = "issue_tags",
							is_focusable = false,
							align = "center",
							border_style = c.ui.border,
							border_label = "Tags",
							lines = signal_issue.tags,
						})
					)
				),
				n.box(
					{
						direction = "row",
						flex = 0,
						border_style = c.ui.border,
					},
					n.text_input({
						flex = 1,
						id = "command",
						border_style = c.ui.border,
						border_label = "Command",
						value = signal_issue.command,
						autofocus = true,
						autoresize = false,
						size = 1,
						placeholder = "Enter a command to apply to issue...",
						max_lines = 1,
						on_change = function(value, _)
							signal_issue.command = value
						end,
						on_mount = function(component)
							utils.set_component_value(component)
						end,
					}),
					n.gap(1),
					n.button({
						label = "Save <C-s>",
						border_style = c.ui.border,
						autofocus = false,
						global_press_key = "<C-s>",
						on_press = function()
							if signal_issue.issue:get_value() == nil then
								return
							end

							local description = renderer:get_component_by_id("issue_description")
							local summary = renderer:get_component_by_id("issue_summary")
							if description ~= nil and summary ~= nil then
								local summary_content = utils.get_component_buffer_content(summary)
								local description_content = utils.get_component_buffer_content(description)

								local s = vim.fn.join(summary_content or {}, "\n")
								local d = vim.fn.join(description_content or {}, "\n")

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
											log.p.error(err)

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
									function(err, _)
										if err then
											log.p.error(err)

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
							if comment ~= nil and utils.get_component_buffer_content(comment) then
								lib.add_issue_comment({
									id = signal_issue.issue:get_value().id,
									comment = vim.fn.join(utils.get_component_buffer_content(comment), "\n"),
								}, function(err, _)
									if err then
										log.p.error(err)

										return
									end

									log.info("Comment applied to issue: %s", signal_issue.issue:get_value().text)

									vim.schedule(function()
										utils.set_component_buffer_content(comment, "")
									end)

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
						border_style = c.ui.border,
						on_press = function()
							signal_issue.should_refresh = true
						end,
					}),
					n.gap(1),
					n.button({
						label = "Open <C-o>",
						global_press_key = "<C-o>",
						autofocus = false,
						border_style = c.ui.border,
						on_press = function()
							vim.ui.open(("%s/issue/%s"):format(c.url, signal_issue.issue:get_value().text))
						end,
					}),
					n.gap(1),
					n.button({
						label = "Close <C-x>",
						global_press_key = "<C-x>",
						autofocus = false,
						border_style = c.ui.border,
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

	lib.get_saved_queries(nil, function(err, res)
		local queries = { { name = "Create a new query...", query = "" } }

		vim.list_extend(queries, c.queries)

		if err then
			log.p.error(err)
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

		signal.active:observe(function(active)
			local local_ui = vim.tbl_deep_extend("force", {}, c.ui, c[active].ui or {})

			renderer:set_size(utils.calculate_ui(local_ui))

			utils.attach_resize(augroup, renderer, local_ui)
		end)

		signal.error:observe(function(err)
			if not err then
				return
			end

			local error = renderer:get_component_by_id("error")
			if error ~= nil then
				vim.schedule(function()
					utils.set_component_buffer_content(error, err or {})
				end)
			end

			signal.active = "error"
		end)

		signal_issues.query:debounce(c.debounce):observe(function(query)
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
					local line = {
						n.text(("[%s]"):format(res.project.text), "@class"),
						n.text(" "),
						n.text(res.text, "@constant"),
					}

					signal_issue.header = {
						n.line(unpack(line)),
					}
				end

				local issue_summary = renderer:get_component_by_id("issue_summary")
				if issue_summary ~= nil then
					vim.schedule(function()
						utils.set_component_buffer_content(issue_summary, res.summary)
					end)
				end

				local issue_description = renderer:get_component_by_id("issue_description")
				if issue_description ~= nil then
					vim.schedule(function()
						utils.set_component_buffer_content(issue_description, res.description)
					end)
				end

				local issue_tags = renderer:get_component_by_id("issue_tags")
				if issue_tags ~= nil then
					local lines = {}

					for _, tag in ipairs(res.tags) do
						table.insert(lines, { n.text(("(%s)"):format(tag.name), "@tag") })
					end

					if #lines > 0 then
						signal_issue.tags = vim.tbl_map(function(line)
							return n.line(unpack(line))
						end, lines)
					else
						signal_issue.tags = ""
					end
				end

				local issue_fields = renderer:get_component_by_id("issue_fields")
				if issue_fields ~= nil then
					local lines = {}

					for _, field in ipairs(res.fields) do
						table.insert(lines, {
							n.text("[", "@constant"),
							n.text(field.name, "@constant"),
							n.text(": ", "@comment"),
							n.text(field.text),
							n.text("]", "@constant"),
						})
					end
					if #lines > 0 then
						signal_issue.fields = vim.tbl_map(function(line)
							return n.line(unpack(line))
						end, lines)
					else
						signal_issue.fields = ""
					end
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

					vim.schedule(function()
						utils.set_component_buffer_content(issue_comments, comments)
					end)
				end

				signal.active = "issue"
			end)
		end)

		signal_issue.should_refresh:observe(function(should_refresh)
			if signal_issue.issue:get_value() == nil then
				log.debug("Issue is nil so can not refresh.")

				return
			end

			if should_refresh then
				log.debug("Should refresh the given issue: %s", signal_issue.issue:get_value().text)
				local issue = signal_issues.issue:get_value()
				signal_issues.issue = nil
				signal_issues.issue = issue
				signal_issue.should_refresh = nil

				log.info("Issue refreshed: %s", signal_issue.issue:get_value().text)
			end
		end)
	end)
end

---@class youtrack.CreateIssueOptions

---@param opts? youtrack.CreateIssueOptions
function M.create_issue(opts)
	opts = opts or {}

	local c = config.read()

	if M._.renderer ~= nil then
		M._.renderer:close()

		return
	end

	local ui = vim.tbl_deep_extend("force", {}, utils.calculate_ui(c.ui), utils.calculate_ui(c.create_issue.ui), {
		position = "50%",
		relative = "editor",
	})
	local renderer = n.create_renderer(ui)
	local augroup = "youtrack_create_issue"

	renderer:add_mappings({
		{
			mode = { "n" },
			key = "q",
			handler = function()
				renderer:close()
			end,
		},
	})

	renderer:on_mount(function()
		M._.renderer = renderer

		utils.attach_resize(augroup, renderer, ui)

		if c.ui.autoclose then
			utils.attach_autoclose(renderer)
		end
	end)

	renderer:on_unmount(function()
		M._.renderer = nil

		pcall(vim.api.nvim_del_augroup_by_name, augroup)
	end)

	local signal_issue = n.create_signal({
		header = {},
		project = nil,
		-- fields = {},
		-- tags = {},
	})

	local body = n.rows(
		{ flex = 1 },
		n.columns(
			{ flex = 0 },
			n.buffer({
				border_style = c.ui.border,
				border_label = "Summary",
				flex = 4,
				size = 1,
				id = "issue_summary",
				buf = utils.create_buffer(false, true),
				autoscroll = false,
				autofocus = true,
				filetype = "markdown",
			}),
			n.paragraph({
				id = "issue_header",
				border_style = c.ui.border,
				align = "center",
				is_focusable = false,
				flex = 3,
				size = 1,
				border_label = "Issue",
				lines = signal_issue.header,
			})
		),
		n.columns(
			{ flex = 1 },
			n.rows(
				{ flex = 4 },
				n.buffer({
					border_style = c.ui.border,
					border_label = "Description",
					flex = 1,
					id = "issue_description",
					buf = utils.create_buffer(false, true),
					autoscroll = false,
					autofocus = false,
					filetype = "markdown",
				})
			)
		),
		n.box(
			{
				direction = "row",
				flex = 0,
				border_style = c.ui.border,
			},
			n.button({
				label = "Save <C-s>",
				border_style = c.ui.border,
				autofocus = false,
				global_press_key = "<C-s>",
				on_press = function()
					local description = renderer:get_component_by_id("issue_description")
					local summary = renderer:get_component_by_id("issue_summary")
					if description ~= nil and summary ~= nil then
						local summary_content = utils.get_component_buffer_content(summary)
						local description_content = utils.get_component_buffer_content(description)

						local s = vim.fn.join(summary_content or {}, "\n")
						local d = vim.fn.join(description_content or {}, "\n")
						-- create the issue here

						lib.create_issue({
							project = signal_issue.project:get_value().id,
							summary = s,
							description = d,
						}, function(err, res)
							if err then
								log.p.error(err)

								return
							end

							log.info(
								"Issue created in project: %s -> %s",
								signal_issue.project:get_value().text,
								res.text
							)

							renderer:close()

							M.get_issues({ issue = { id = res.id } })
						end)
					end
				end,
			}),
			n.gap(1),
			n.button({
				label = "Close <C-x>",
				global_press_key = "<C-x>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					renderer:close()
				end,
			})
		)
	)

	lib.get_projects(nil, function(err, res)
		if err then
			log.p.error(err)

			return
		end

		vim.ui.select(res, {
			prompt = "Select project",
			format_item = function(item)
				return item.text
			end,
		}, function(project)
			if project == nil then
				return
			end

			signal_issue.header = {
				n.line(n.text(("[%s]"):format(project.text), "@class"), n.text(" "), n.text("Draft", "@constant")),
			}
			signal_issue.project = project

			renderer:render(body)
		end)
	end)
end

return M
