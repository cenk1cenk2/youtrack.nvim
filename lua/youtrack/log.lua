-- Inspired by rxi/log.lua
-- Modified by tjdevries and can be found at github.com/tjdevries/vlog.nvim
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.

---@class youtrack.Logger: youtrack.LogAtLevel
---@field setup youtrack.LoggerSetupFn
---@field config youtrack.LoggerConfig
---@field p youtrack.LogAtLevel

---@class youtrack.LogAtLevel
---@field trace fun(...: any): string
---@field debug fun(...: any): string
---@field info fun(...: any): string
---@field warn fun(...: any): string
---@field error fun(...: any): string

---@class youtrack.Logger
local M = {
	---@diagnostic disable-next-line: missing-fields
	p = {},
}

---@class youtrack.LoggerConfig
---@field level number
---@field plugin string
---@field modes youtrack.LoggerMode[]

---@class youtrack.LoggerMode
---@field name string
---@field level number

---@type youtrack.LoggerConfig
M.config = {
	level = vim.log.levels.INFO,
	plugin = "schema-companion.nvim",
	modes = {
		{ name = "trace", level = vim.log.levels.TRACE },
		{ name = "debug", level = vim.log.levels.DEBUG },
		{ name = "info", level = vim.log.levels.INFO },
		{ name = "warn", level = vim.log.levels.WARN },
		{ name = "error", level = vim.log.levels.ERROR },
	},
}

---@class youtrack.LoggerSetup
---@field level? number

---@alias youtrack.LoggerSetupFn fun(config?: youtrack.LoggerSetup): youtrack.Logger

---@type youtrack.LoggerSetupFn
function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})

	local log = function(mode, sprintf, ...)
		if mode.level < M.config.level then
			return
		end

		local info = debug.getinfo(2, "Sl")
		local lineinfo = ("%s:%s"):format(info.short_src, info.currentline)

		local console = string.format("[%-5s] [%s]: %s", mode.name:upper(), lineinfo, sprintf(...))

		for _, line in ipairs(vim.split(console, "\n")) do
			vim.notify(([[[%s] %s]]):format(M.config.plugin, line), mode.level)
		end
	end

	for _, mode in pairs(M.config.modes) do
		---@diagnostic disable-next-line: assign-type-mismatch
		M[mode.name] = function(...)
			return log(mode, function(...)
				local passed = { ... }
				local fmt = table.remove(passed, 1)
				local inspected = {}

				for _, v in ipairs(passed) do
					table.insert(inspected, vim.inspect(v))
				end

				return fmt:format(unpack(inspected))
			end, ...)
		end

		---@diagnostic disable-next-line: assign-type-mismatch
		M.p[mode.name] = function(...)
			return log(mode, function(...)
				local passed = { ... }
				local fmt = table.remove(passed, 1)

				return fmt
			end, ...)
		end
	end

	return M
end

function M.set_log_level(level)
	M.config.level = level

	return level
end

return M
