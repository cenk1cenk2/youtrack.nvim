# youtrack.nvim

For the intersection set of handful of people that is using Youtrack and Neovim together. This plugin enables you to interact with Youtrack from Neovim.

## Features

- Get issues from Youtrack, and list them and their details.
  - Get your saved queries, and modify them realtime to list matching issues. ![demo](./media/swappy-20240914_000532.png) ![demo](./media/swappy-20240914_000634.png)
  - Get issue details, and modify them realtime. ![demo](./media/swappy-20240914_000705.png)
  - View comment on the issue and add new comments. ![demo](./media/swappy-20240914_000730.png)
  - Apply commands to the issue. ![demo](./media/swappy-20240914_000749.png)
  - Open issue in the browser.
- Create new issues in Youtrack.
  - Create a new issue in the project and fill the basic data. ![demo](./media/swappy-20240915_155805.png) ![demo](./media/swappy-20240915_155825.png)
  - Drop down to issue detail view to further fill the details. ![demo](./media/swappy-20240915_155833.png)
- Open and search agile boards. ![demo](./media/swappy-20240915_162015.png)

## Requirements

Even though this plugin could purely created with `lua`, I wanted to exercise with `rust` and `lua` bindings since I created this plugin for mostly myself and handful of people that is in the intersection set. You need to have `rust` installed in your system to build the plugin backend.

- `rust` has to be installed in your system to compile the backend.
- `make` has to be installed in your system to build the plugin.

## Installation

### `lazy.nvim`

```lua
{
    "cenk1cenk2/youtrack.nvim",
    build = { "make" },
    dependencies = {
      -- https://github.com/MunifTanjim/nui.nvim
      "MunifTanjim/nui.nvim",
      -- https://github.com/grapp-dev/nui-components.nvim
      "grapp-dev/nui-components.nvim",
    }
}
```

## Configuration

### Setup

Plugin requires `url` and `token` to be set in the configuration.

```lua
require("youtrack").setup({
	url = vim.env["YOUTRACK_URL"],
	token = vim.env["YOUTRACK_TOKEN"],
})
```

You can check the full configuration in [here](https://github.com/cenk1cenk2/youtrack.nvim/blob/main/lua/youtrack/config.lua).

### Adding Additional Queries

You can add additional queries to your saved ones directly in the `lua` configuration.

```lua
require("youtrack").setup({
	-- rest of the configuration...
	queries = { "for: me" },
})
```

### Limiting Fields

You can limit custom fields to the view, this will limit the cluter you will see in the given view.

```lua
require("youtrack").setup({
	-- rest of the configuration...
	-- to limit the fields in the get issues view
	issues = {
		fields = { "State" },
	},
	issue = {
		-- to limit the fields in the get issue detail view
		fields = { "State", "Subsystem", "Timer" },
	},
})
```

### UI Configuration

UI parameters can be passed in to further customize the global keymaps and size per view.

```lua
require("youtrack").setup({
	-- rest of the configuration...
	-- global ui configuration
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
	-- sizing for specific views
	issues = {
		size = {
			height = 24,
			width = 180,
		},
	},
	issue = {
		size = {
			height = 48,
			width = 180,
		},
	},
})
```

## Usage

This plugin is designed to toggle different views directly.

So you can map the following calls into any keybind.

### Saved Query Selector

Shows the saved queries and with the selected opens the issues view.

```lua
--- open with saved queries
require("youtrack").get_queries()
```

### Issues View

Lists the saved queries, and allow you to modify them to list the issues. You can open the issue details by pressing `Enter`.

```lua
-- open with saved queries same as get_queries
require("youtrack").get_issues()

-- open a specific issue
require("youtrack").get_issues({ query = "for: me" })
```

### Issue View

Shows a specific issue details, and allows you to modify the issue, add comments, and apply commands.

```lua
-- get the last open issue
require("youtrack").get_issues()

-- get a specific issue
require("youtrack").get_issues({ id = "NVIM-365" })

-- reset the saved last issue
require("youtrack").reset_last_issue()
```

### Create Issue View

Create a new basic issue in the project then list the detail of it.

```lua
require("youtrack").create_issue()
```

### Board Selector

List and open a board in the browser.

```lua
require("youtrack").get_agiles()
```

## References

The UI is only possible due to beautiful work done on [MunifTanjim/nui.nvim](https://github.com/MunifTanjim/nui.nvim) and [grapp-dev/nui-components.nvim](https://github.com/grapp-dev/nui-components.nvim).

Thanks to following plugins for inspiration:

- [Arekkusuva/jira-nvim](https://github.com/Arekkusuva/jira-nvim)
