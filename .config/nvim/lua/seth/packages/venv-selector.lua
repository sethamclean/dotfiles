-- venv-selector.nvim configuration for LazyVim
-- See: https://github.com/linux-cultist/venv-selector.nvim
return {
	"linux-cultist/venv-selector.nvim",
	branch = "regexp",
	dependencies = {
		"neovim/nvim-lspconfig",
		"nvim-telescope/telescope.nvim",
		"mfussenegger/nvim-dap-python",
	},
	config = function()
		require("venv-selector").setup({
			auto_activate = true,
			search_venv_names = { "venv", "env", ".venv", ".env" },
			-- Add or update other options as needed from the regexp branch docs
		})
	end,
	event = "VeryLazy",
	keys = {
		{ "<leader>vs", "<cmd>VenvSelect<cr>" },
		{ "<leader>vc", "<cmd>VenvSelectCached<cr>" },
	},
}
