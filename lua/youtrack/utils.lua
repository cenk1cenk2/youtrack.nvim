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

function M.render_custom_fields(res)
	local fields = {}
	for _, field in ipairs(res.customFields) do
		if field["$type"] == "PeriodIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-PeriodIssueCustomField.html
			table.insert(fields, ("[ %s: %s ]"):format(field.name, field.value.presentation))
		elseif field["$type"] == "DateIssueCustomField" and type(field.value) ~= "userdata" then
			-- https://www.jetbrains.com/help/youtrack/devportal/api-entity-DateIssueCustomField.html
			table.insert(fields, ("[ %s: %s ]"):format(field.name, os.date("%Y%m%dT%H:%M:%S", field.value / 1000)))
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

	return fields
end

return M
