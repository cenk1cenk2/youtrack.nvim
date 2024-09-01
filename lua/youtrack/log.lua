-- Inspired by rxi/log.lua
-- Modified by tjdevries and can be found at github.com/tjdevries/vlog.nvim
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--

---@class youtrack.Logger
---@field new youtrack.LoggerNew
---@field config youtrack.LoggerConfig
---@field trace fun(fmt: string, ...: any)
---@field debug fun(fmt: string, ...: any)
---@field info fun(fmt: string, ...: any)
---@field warn fun(fmt: string, ...: any)
---@field error fun(fmt: string, ...: any)

---@class youtrack.Logger
local M = {}

---@class youtrack.LoggerConfig
---@field plugin string
---@field modes youtrack.LoggerMode[]
---@class youtrack.LoggerMode
---@field name string
---@field level number
M.config = {
	plugin = "youtrack.nvim",
	modes = {
		{ name = "trace", level = vim.log.levels.TRACE },
		{ name = "debug", level = vim.log.levels.DEBUG },
		{ name = "info", level = vim.log.levels.INFO },
		{ name = "warn", level = vim.log.levels.WARN },
		{ name = "error", level = vim.log.levels.ERROR },
	},
}

---@alias youtrack.LoggerNew fun(config: youtrack.LoggerConfig): youtrack.Logger

---@type youtrack.LoggerNew
function M.new(config)
	config = vim.tbl_deep_extend("force", {}, M.config, config)

	local log = function(mode, sprintf, ...)
		local info = debug.getinfo(2, "Sl")
		local lineinfo = ("%s:%s"):format(info.short_src, info.currentline)

		local console = string.format("[%-5s%s]: %s", mode.name:upper(), lineinfo, sprintf(...))

		for _, line in ipairs(vim.split(console, "\n")) do
			vim.notify(([[[%s] %s]]):format(config.plugin, line), mode.level)
		end
	end

	for _, mode in pairs(config.modes) do
		M[mode.name] = function(...)
			return log(mode, function(...)
				local passed = { ... }
				local fmt = table.remove(passed, 1)
				local inspected = {}

				for _, v in ipairs(passed) do
					table.insert(inspected, vim.inspect(v))
				end

				return string.format(fmt, unpack(inspected))
			end, ...)
		end
	end

	return M
end

return M
