local M = {}

---@class youtrack.Config
---@field log_level? number
---@field url string
---@field token string
---@field debounce? number
---@field ui? youtrack.ConfigUi
---@field queries? youtrack.Query[]
---@field issues? youtrack.ConfigIssues
---@field issue? youtrack.ConfigIssue
---@field create_issue? youtrack.ConfigCreateIssue

---@class youtrack.ConfigUi: youtrack.ConfigUiSize
---@field autoclose? boolean
---@field border? 'double' | 'none' | 'rounded' | 'shadow' | 'single' | 'solid'
---@field keymap? youtrack.ConfigUIKeymap

---@class youtrack.ConfigUiSize
---@field width? number | (fun(columns: number): number?)
---@field height? number | (fun(lines: number): number?)

---@class youtrack.ConfigUIKeymap
---@field close? string
---@field focus_next? string
---@field focus_prev? string
---@field focus_left? string
---@field focus_right? string
---@field focus_up? string
---@field focus_down? string

---@class youtrack.ConfigIssues
---@field fields? table<youtrack.ConfigFields>
---@field ui? youtrack.ConfigUiSize

---@class youtrack.ConfigIssue
---@field fields? table<youtrack.ConfigFields>
---@field ui? youtrack.ConfigUiSize

---@class youtrack.ConfigCreateIssue
---@field ui? youtrack.ConfigUiSize

---@alias youtrack.ConfigFields table<string>

---@class youtrack.Query
---@field name string
---@field query string

---@type youtrack.Config
local defaults = {
	log_level = vim.log.levels.INFO,
	url = "",
	token = "",
	debounce = 500,
	ui = {
		autoclose = true,
		border = "single",
		width = function(columns)
			if columns < 180 then
				return math.floor(columns * 0.95)
			end

			return 180
		end,
		height = function(lines)
			if lines < 48 then
				return math.floor(lines * 0.95)
			end

			return 24
		end,
		keymap = {
			close = "<Esc>",
			focus_next = "<Tab>",
			focus_prev = "<S-Tab>",
			focus_left = nil,
			focus_right = nil,
			focus_up = nil,
			focus_down = nil,
		},
	},
	queries = {},
	issues = {
		fields = {},
	},
	issue = {
		ui = {
			width = function(columns)
				if columns < 180 then
					return math.floor(columns * 0.95)
				end

				return 180
			end,
			height = function(lines)
				if lines < 48 then
					return math.floor(lines * 0.95)
				end

				return 48
			end,
		},
		fields = {},
	},
	create_issue = {},
}

---@type youtrack.Config
---@diagnostic disable-next-line: missing-fields
M.options = nil

---@return youtrack.Config
function M.read()
	return M.options
end

---@param config youtrack.Config
---@return youtrack.Config
function M.setup(config)
	M.options = vim.tbl_deep_extend("force", {}, defaults, config or {})

	return M.options
end

return M
