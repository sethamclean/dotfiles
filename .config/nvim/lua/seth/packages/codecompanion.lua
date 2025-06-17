return {
	"olimorris/codecompanion.nvim",
	version = "v16.1.0",
	opts = {},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"ravitemer/mcphub.nvim",
		"ravitemer/codecompanion-history.nvim",
		"folke/noice.nvim",
	},
	config = function()
		require("codecompanion").setup({
			display = {
				chat = {
					show_settings = true, -- Show settings in chat buffer
					show_model = true, -- Show model name in chat buffer
					show_adapter = true, -- Show adapter name in chat buffer
					show_time = true, -- Show time in chat buffer
					show_title = true, -- Show title in chat buffer
				},
			},
			extensions = {
				mcphub = {
					callback = "mcphub.extensions.codecompanion",
					opts = {
						-- Disabled this because SearXNG produces a lot of output
						-- show_result_in_chat = true, -- Show mcp tool results in chat
						make_vars = true, -- Convert resources to #variables
						make_slash_commands = true, -- Add prompts as /slash commands
					},
				},
				vectorcode = {
					opts = {
						add_tool = true,
					},
				},
				history = {
					enabled = true,
					opts = {
						-- Keymap to open history from chat buffer (default: gh)
						keymap = "gh",
						-- Keymap to save the current chat manually (when auto_save is disabled)
						save_chat_keymap = "sc",
						-- Save all chats by default (disable to save only manually using 'sc')
						auto_save = true,
						-- Number of days after which chats are automatically deleted (0 to disable)
						expiration_days = 0,
						-- Picker interface ("telescope" or "snacks" or "fzf-lua" or "default")
						picker = "telescope",
						---Automatically generate titles for new chats
						auto_generate_title = true,
						title_generation_opts = {
							---Adapter for generating titles (defaults to active chat's adapter)
							adapter = nil, -- e.g "copilot"
							---Model for generating titles (defaults to active chat's model)
							model = nil, -- e.g "gpt-4o"
						},
						---On exiting and entering neovim, loads the last chat on opening chat
						continue_last_chat = false,
						---When chat is cleared with `gx` delete the chat from history
						delete_on_clearing_chat = false,
						---Directory path to save the chats
						dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
						---Enable detailed logging for history extension
						enable_logging = false,
					},
				},
			},
		})
		-- Keymaps
		vim.keymap.set("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "CodeCompanion Action Palette" })
		-- Notifications on companion events
		require("seth.ui.companion-notification").init()
		-- Set up the chat buffer with default tools
		vim.api.nvim_create_autocmd("User", {
			pattern = "CodeCompanionChatCreated",
			group = group,
			callback = function(event)
				local lines = vim.api.nvim_buf_get_lines(event.buf, 0, -1, false)
				local insert_pos = nil
				for i, line in ipairs(lines) do
					if line:match("^## Me") then
						insert_pos = i
						break
					end
				end
				if insert_pos then
					vim.api.nvim_buf_set_lines(event.buf, insert_pos, insert_pos, false, {
						"",
						"@full_stack_dev @mcp @vectorcode",
						"",
					})
				end
			end,
		})
	end,
}
