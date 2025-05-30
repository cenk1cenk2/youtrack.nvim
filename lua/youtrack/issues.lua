local M = {
	_ = require("youtrack.state"),
}

local lib = require("youtrack.lib")
local log = require("youtrack.log")
local n = require("nui-components")
local config = require("youtrack.config")
local utils = require("youtrack.utils")

---@class youtrack.GetIssuesOptions
---@field query? string The query to search for issues.

---@param opts? youtrack.GetIssuesOptions
function M.get_issues(opts)
	opts = opts or {}

	local c = config.read()

	if M._.renderer ~= nil then
		M._.renderer:close()

		return
	end

	local last_query = vim.g.SHADA_YOUTRACK_NVIM_LAST_QUERY

	if opts.query == nil and last_query ~= nil then
		opts.query = last_query
	end

	if opts.query == nil then
		log.error("No query has been provided and there is no last state.")

		return
	end

	local ui = vim.tbl_deep_extend("force", {}, utils.calculate_ui(c.ui), {
		position = "50%",
		relative = "editor",
	})
	local renderer = n.create_renderer(ui)
	local augroup = "youtrack_issues"

	renderer:on_mount(function()
		M._.renderer = renderer

		renderer:set_size(utils.calculate_ui(vim.tbl_deep_extend("force", {}, c.ui, c.issues.ui or {})))

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
		error = nil,
	})

	local signal_issues = n.create_signal({
		query = "",
		issues = {},
		issue = nil,
		should_refresh = nil,
	})

	local body = n.rows(
		{ flex = 1 },
		--- text input for query
		n.text_input({
			id = "query",
			border_style = c.ui.border,
			autofocus = true,
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
			autofocus = false,
			on_select = function(node, component)
				signal_issues.issue = node
			end,
			prepare_node = function(node, line, component)
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

				if node._focused then
					component:focus()
				end

				return line
			end,
		}),
		n.box(
			{
				direction = "row",
				flex = 0,
				border_style = c.ui.border,
			},
			n.button({
				label = "Queries <C-s>",
				global_press_key = "<C-s>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					renderer:close()

					require("youtrack.queries").get_queries()
				end,
			}),
			n.gap(1),
			n.button({
				label = "Query <C-f>",
				global_press_key = "<C-f>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					local component = renderer:get_component_by_id("query")
					if component ~= nil then
						component:focus()
					end
				end,
			}),
			n.gap(1),
			n.button({
				label = "Create <C-c>",
				global_press_key = "<C-c>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					renderer:close()

					M.create_issue()
				end,
			}),
			n.gap(1),
			n.button({
				label = "Refresh <C-r>",
				global_press_key = "<C-r>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					signal_issues.should_refresh = true
				end,
			}),
			n.gap(1),
			n.button({
				label = "Open <C-o>",
				global_press_key = "<C-o>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					vim.ui.open(("%s/search/?q=%s"):format(c.url, signal_issues.query:get_value()))
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

	signal_issues.query = opts.query

	renderer:render(body)

	signal.error:observe(function(err)
		if not err then
			return
		end

		log.error(err)
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
				if component ~= nil then
					component:set_border_text("bottom", "error", "right")
				end

				return
			end

			if #res == 0 then
				signal_issues.issues = {}
				if component ~= nil then
					component:set_border_text("bottom", "no match", "right")
				end

				return
			end

			if #res > 1 then
				res[1]._focused = true
			end

			signal_issues.issues = vim.tbl_map(function(issue)
				return n.node(issue)
			end, res or {})

			if component ~= nil then
				component:set_border_text("bottom", ("matches: %d"):format(#(res or {})), "right")
			end
		end)

		vim.g.SHADA_YOUTRACK_NVIM_LAST_QUERY = query
	end)

	signal_issues.issue:observe(function(issue)
		if issue == nil then
			return
		end

		renderer:close()

		vim.schedule(function()
			M.get_issue({ id = issue.id })
		end)
	end)

	signal_issues.should_refresh:observe(function(should_refresh)
		if signal_issues.query:get_value() == nil then
			log.debug("Query nil so can not refresh.")

			return
		end

		if should_refresh then
			log.debug("Should refresh the given query: %s", signal_issues.query:get_value())
			local q = signal_issues.query:get_value()
			signal_issues.query = nil
			signal_issues.query = q
			signal_issues.should_refresh = nil

			log.info("Query refreshed: %s", signal_issues.query:get_value())
		end
	end)
end

---@class youtrack.GetIssueOptions
---@field id? string For passing in from other components to see the issue detail.

---@param opts? youtrack.GetIssueOptions
function M.get_issue(opts)
	opts = opts or {}

	local last_issue = vim.g.SHADA_YOUTRACK_NVIM_LAST_ISSUE

	if opts.id == nil and last_issue ~= nil then
		opts.id = last_issue
	end

	if opts.id == nil then
		log.error("No issue id has been provided and there is no last window.")

		return
	end

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
	local augroup = "youtrack_issue"

	renderer:on_mount(function()
		M._.renderer = renderer

		renderer:set_size(utils.calculate_ui(vim.tbl_deep_extend("force", {}, c.ui, c.issue.ui or {})))

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
		error = nil,
	})

	local signal_issue = n.create_signal({
		id = opts.id,
		issue = nil,
		should_refresh = nil,
		header = {},
		fields = {},
		tags = {},
		command = "",
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
				buf = utils.create_buffer(true),
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
					buf = utils.create_buffer(true),
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
					buf = utils.create_buffer(false),
					autoscroll = false,
					autofocus = false,
					filetype = "markdown",
					border_label = "Comments",
				}),
				n.buffer({
					id = "comment",
					flex = 1,
					buf = utils.create_buffer(true),
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
				label = "Issues <C-f>",
				global_press_key = "<C-f>",
				autofocus = false,
				border_style = c.ui.border,
				on_press = function()
					renderer:close()

					M.get_issues()
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

								utils.set_component_buffer_content(command, nil)

								signal_issue.should_refresh = true
							end
						)
					else
						log.debug("No command to be applied for the issue: %s", signal_issue.issue:get_value().text)
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

							utils.set_component_buffer_content(comment, nil)

							signal_issue.should_refresh = true
						end)
					else
						log.debug("No comment to be applied for the issue: %s", signal_issue.issue:get_value().text)
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
					renderer:close()
				end,
			})
		)
	)

	local render = function()
		renderer:render(body)

		signal.error:observe(function(err)
			if not err then
				return
			end

			log.error(err)
		end)

		signal_issue.should_refresh:observe(function(should_refresh)
			if should_refresh then
				local issue_header = renderer:get_component_by_id("issue_header")
				if issue_header ~= nil then
					issue_header:set_border_text("bottom", "running...", "right")
				end

				log.debug("Should refresh the given issue: %s", opts.id)

				lib.get_issue({ id = opts.id }, function(err, res)
					if err then
						signal.error = err
						if issue_header ~= nil then
							issue_header:set_border_text("bottom", "error", "right")
						end

						return
					end

					signal_issue.issue = res

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
						utils.set_component_buffer_content(issue_summary, res.summary)
					end

					local issue_description = renderer:get_component_by_id("issue_description")
					if issue_description ~= nil then
						utils.set_component_buffer_content(issue_description, res.description)
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

						utils.set_component_buffer_content(issue_comments, comments)
					end

					if issue_header ~= nil then
						issue_header:set_border_text("bottom", nil, "right")
					end
					signal.active = "issue"
				end)

				signal_issue.should_refresh = nil
			end
		end)
	end

	signal_issue.should_refresh = true
	vim.g.SHADA_YOUTRACK_NVIM_LAST_ISSUE = opts.id
	render()
end

function M.reset_lasts()
	log.info("Resetting saved state for lasts.")

	vim.g.SHADA_YOUTRACK_NVIM_LAST_QUERY = nil
	vim.g.SHADA_YOUTRACK_NVIM_LAST_ISSUE = nil
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
				buf = utils.create_buffer(true),
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
					buf = utils.create_buffer(true),
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

							M.get_issue({ id = res.id })
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
