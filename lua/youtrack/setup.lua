---@class youtrack.Config
---@field url string
---@field token string
---@field ui? youtrack.ConfigUI
---@field issues? youtrack.ConfigIssues

---@class youtrack.ConfigUI
---@field border? 'double' | 'none' | 'rounded' | 'shadow' | 'single' | 'solid'
---@field width? number
---@field keymap? youtrack.ConfigUIKeymap

---@class youtrack.ConfigUIKeymap
---@field close? string
---@field focus_next? string
---@field focus_prev? string
---@field focus_left? string
---@field focus_right? string
---@field focus_up? string
---@field focus_down? string

---@class youtrack.ConfigIssues
---@field queries? youtrack.ConfigIssuesQuery[]

---@class youtrack.ConfigIssuesQuery
---@field name string
---@field query string

local M = {}

---@type youtrack.Config
M.config = {
	ui = {
		border = "single",
		width = 120,
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
	issues = {
		queries = {},
	},
}

---@param config youtrack.Config
function M.setup(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})

	return M.config
end

return M
