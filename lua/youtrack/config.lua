local M = {}

---@class youtrack.Config
---@field log_level? number
---@field url string
---@field token string
---@field debounce? number
---@field ui? youtrack.ConfigUi
---@field queries? string[]
---@field issues? youtrack.ConfigIssues
---@field issue? youtrack.ConfigIssue

---@class youtrack.ConfigUi: youtrack.ConfigUiSize
---@field autoclose? boolean
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
---@field ui? youtrack.ConfigUiSize

---@class youtrack.ConfigIssue
---@field fields? table<youtrack.ConfigFields>
---@field ui? youtrack.ConfigUiSize

---@alias youtrack.ConfigFields table<string>

---@type youtrack.Config
local defaults = {
	log_level = vim.log.levels.INFO,
	url = "",
	token = "",
	debounce = 500,
	ui = {
		autoclose = true,
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
		ui = {
			height = 24,
			width = 180,
		},
		fields = {},
	},
	issue = {
		ui = {
			height = 48,
			width = 180,
		},
		fields = {},
	},
}

---@type youtrack.Config
---@diagnostic disable-next-line: missing-fields
M.options = nil

---@return youtrack.Config
function M.read()
	return M.options
end

---Calculate the size of the UI.
---@param size youtrack.ConfigUiSize
---@return  youtrack.ConfigUiSize
local function calculate_size(size)
	if size.width and size.width <= 1 and size.width > 0 then
		size.width = math.floor(vim.o.columns * size.width)
	end
	if size.height and size.height <= 1 and size.height > 0 then
		size.height = math.floor(vim.o.lines * size.height)
	end

	return size
end

---@param config youtrack.Config
---@return youtrack.Config
function M.setup(config)
	M.options = vim.tbl_deep_extend("force", {}, defaults, config or {})

	calculate_size(M.options.ui)
	calculate_size(M.options.issues.size)
	calculate_size(M.options.issue.size)

	return M.options
end

return M
