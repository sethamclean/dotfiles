return {
	{
		"epwalsh/obsidian.nvim",
		version = "*", -- use latest release instead of latest commit
		ft = "markdown",
		dependencies = {
			-- Required
			"nvim-lua/plenary.nvim",

			-- Optional, for completion
			"hrsh7th/nvim-cmp",

			-- Optional, for search
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			workspaces = {
				{
					name = "main",
					path = vim.fn.expand("~/Documents/obsidian-vault/main"),
				},
			},

			-- Basic settings
			completion = {
				nvim_cmp = true,
				min_chars = 2,
			},

			-- Simple key mappings
			mappings = {
				["gf"] = {
					action = function()
						return require("obsidian").util.gf_passthrough()
					end,
					opts = { noremap = false, expr = true, buffer = true },
				},
				["<leader>ob"] = {
					action = function()
						return require("obsidian").commands.open_browser()
					end,
					opts = { buffer = true },
				},
				["<leader>oc"] = {
					action = function()
						return require("obsidian").util.toggle_checkbox()
					end,
					opts = { buffer = true },
				},
			},
		},
	},
}
