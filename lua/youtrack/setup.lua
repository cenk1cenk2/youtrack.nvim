---@class youtrack.Config
---@field log_level? number
---@field url string
---@field token string
---@field ui? youtrack.ConfigUi
---@field queries? string[]
---@field issues? youtrack.ConfigIssues
---@field issue? youtrack.ConfigIssue

---@class youtrack.ConfigUi: youtrack.ConfigUiSize
---@field border? 'double' | 'none' | 'rounded' | 'shadow' | 'single' | 'solid'
---@field keymap? youtrack.ConfigUIKeymap

---@class youtrack.ConfigUiSize
---@field width? number
---@field height? number

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
---@field size? youtrack.ConfigUiSize

---@class youtrack.ConfigIssue
---@field fields? table<youtrack.ConfigFields>
---@field size? youtrack.ConfigUiSize

---@alias youtrack.ConfigFields table<string>

local M = {}

---@type youtrack.Config
M.config = {
	log_level = vim.log.levels.INFO,
	url = "",
	token = "",
	ui = {
		border = "single",
		width = 180,
		keymap = {
			close = "<Esc>",
			focus_next = "<Tab>",
			focus_prev = "<S-Tab>",
			focus_left = "<Left>",
			focus_right = "<Right>",
			focus_up = "<Up>",
			focus_down = "<Down>",
		},
	},
	queries = {},
	issues = {
		size = {
			height = 24,
			width = 180,
		},
		fields = {},
	},
	issue = {
		size = {
			height = 48,
			width = 180,
		},
		fields = {},
	},
}

---@param config youtrack.Config
---@return youtrack.Config
function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})

	return M.config
end

return M
