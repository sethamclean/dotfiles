-- venv-selector.nvim configuration for LazyVim
-- See: https://github.com/linux-cultist/venv-selector.nvim

return {
	"linux-cultist/venv-selector.nvim",
	dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
	opts = {
		-- Automatically activate venv when entering a project
		auto_activate = true,
		-- Show venv name in statusline if lualine is present
		name = {
			"venv",
			"env",
			".venv",
			".env",
		}, -- Your options go here
	},
	event = "VeryLazy", -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
	keys = {
		-- Keymap to open VenvSelector to pick a venv.
		{ "<leader>vs", "<cmd>VenvSelect<cr>" },
		-- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
		{ "<leader>vc", "<cmd>VenvSelectCached<cr>" },
	},
}
