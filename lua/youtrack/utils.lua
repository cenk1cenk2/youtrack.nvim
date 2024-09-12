local M = {}

---
---@param component any
---@param value? any
---@return any
function M.set_component_value(component, value)
	vim.schedule(function()
		if not value then
			value = component:get_current_value()
		end

		component:set_current_value(value)
		local lines = component:get_lines()
		vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, true, lines)
		component:redraw()
	end)

	return component
end

local function field_with_color(field, value)
	if type(field.value) == "table" and type(field.value.color) == "table" then
		return vim.tbl_extend("force", value, {
			hl = {
				fg = field.value.color.foreground,
				bg = field.value.color.background,
			},
		})
	end

	return value
end

function M.process_fields(res)
	local fields = {}
	for _, field in ipairs(res.customFields) do
		if field["$type"] == "PeriodIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-PeriodIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.presentation,
				})
			)
		elseif field["$type"] == "DateIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-DateIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = os.date("%Y%m%dT%H:%M:%S", field.value / 1000),
				})
			)
		elseif field["$type"] == "SimpleIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-DateIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value,
				})
			)
		elseif field["$type"] == "StateIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-StateIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
			-- elseif field["$type"] == "SingleBuildIssueCustomField" and type(field.value.name) ~= "userdata" then
			-- 	-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleBuildIssueCustomField.html
			-- 	table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
		elseif field["$type"] == "SingleUserIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleUserIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
		elseif field["$type"] == "SingleGroupIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleGroupIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
		elseif field["$type"] == "SingleVersionIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleVersionIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
		elseif field["$type"] == "SingleOwnedIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-SingleOwnedIssueCustomField.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
		elseif field["$type"] == "SingleEnumIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-EnumBundleElement.html
			table.insert(
				fields,
				field_with_color(field, {
					key = field.name,
					value = field.value.name,
				})
			)
		elseif field["$type"] == "StateMachineIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-StateMachineIssueCustomField.html
			-- table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.name))
		end
	end

	return fields
end

---
---@param component any
---@param content string | string[]
---@param modifable? boolean
---@return any
function M.set_component_buffer_content(component, content, modifable)
	---@type string[]
	local c
	if type(content) == "string" then
		c = vim.fn.split(content, "\n")
	else
		c = content
	end

	if modifable then
		vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, c)
	else
		component:modify_buffer_content(function()
			vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, c)
		end)
	end

	return component
end

---@param component any
---@return string[]
function M.get_component_buffer_content(component)
	return vim.api.nvim_buf_get_lines(component.bufnr, 0, -1, false)
end

return M
