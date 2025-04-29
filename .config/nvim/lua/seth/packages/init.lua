return {
	{
		"nvim-tree/nvim-tree.lua",
		version = "*",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("nvim-tree").setup({})
		end,
	},
	-- Copilot setup
	{
		"zbirenbaum/copilot-cmp",
		dependencies = {
			"zbirenbaum/copilot.lua",
			cmd = "Copilot",
			event = "InsertEnter",
			config = function()
				require("copilot").setup({
					suggestion = {
						enabled = true,
						auto_trigger = true,
						debounce = 75,
						keymap = {
							accept = "<s-Tab>",
							accept_word = false,
							accept_line = false,
							next = "<M-]>",
							prev = "<M-[>",
							dismiss = "<C-]>",
						},
					},
				})
			end,
		},
		config = function()
			require("copilot_cmp").setup()
		end,
	},
	-- Undotree for local revisioning
	{
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "undotree toggle." })
		end,
	},
	-- Add telescope fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.5",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("telescope").setup({
				extensions = {
					tldr = {
						{
							tldr_command = "tldr",
						},
					},
				},
			})
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "telescope find files." })
			vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "telescope find git files." })
			vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "telescope grep." })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "telescope find in buffers." })
			vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "telescope find in commands." })
			vim.keymap.set("n", "<leader>ft", builtin.treesitter, { desc = "telescope find in treesitter." })
			vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "telescope find in keymaps." })
			vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "telescope find in marks." })
			vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "telescope find in jumps." })
			vim.keymap.set("n", "<leader>fp", builtin.man_pages, { desc = "telescope find in man pages." })
		end,
	},
	{
		"mrjones2014/tldr.nvim",
		dependencies = { "nvim-telescope/telescope.nvim" },
		config = function()
			require("tldr").setup()
			vim.keymap.set("n", "<leader>fh", require("tldr").pick, { desc = "telescope tldr help." })
		end,
	},
	-- Add trouble to add lsp violatoin to gutter and quickfix
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},
	-- Git integration
	{
		"lewis6991/gitsigns.nvim",
		dependencies = { "tpope/vim-fugitive" },
		config = function()
			require("gitsigns").setup()
		end,
	},
	-- Avante
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		lazy = false,
		version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
		opts = {
			-- add any opts here
			behaviour = {
				enable_claude_text_editor_tool_mode = true,
				use_cwd_as_project_root = true,
			},
			provider = "copilot",
			copilot = {
				model = "claude-3.7-sonnet",
			},
			-- The system_prompt type supports both a string and a function that returns a string
			-- Using a function here allows dynamically updating the prompt with mcphub
			system_prompt = function()
				local hub = require("mcphub").get_hub_instance()
				return hub:get_active_servers_prompt()
			end,
			-- The custom_tools type supports both a list and a function that returns a list
			-- Using a function here prevents requiring mcphub before it's loaded
			custom_tools = function()
				return {
					require("mcphub.extensions.avante").mcp_tool(),
				}
			end,
		},
		-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
		build = "make",
		-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
		dependencies = {
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			--- The below dependencies are optional,
			"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
			"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
			"zbirenbaum/copilot.lua", -- for providers='copilot'
			"ravitemer/mcphub.nvim", -- for MCP integration
			{
				-- support for image pasting
				"HakonHarnes/img-clip.nvim",
				event = "VeryLazy",
				opts = {
					-- recommended settings
					default = {
						embed_image_as_base64 = false,
						prompt_for_file_name = false,
						drag_and_drop = {
							insert_mode = true,
						},
						-- required for Windows users
						use_absolute_path = true,
					},
				},
			},
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
			},
		},
	},
}
