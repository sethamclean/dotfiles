return {
	"nvimdev/lspsaga.nvim",
	event = "LspAttach",
	config = function()
		require("lspsaga").setup({
			outline = {
				auto_preview = false,
				auto_close = true,
				close_after_jump = true,
				keys = {
					expand_or_jump = { "<CR>", "o" },
					quit = { "<Esc>", "q" },
				},
			},
		})
		vim.keymap.set("n", "<leader>lh", "<cmd>Lspsaga hover_doc<CR>")
		vim.keymap.set("n", "<leader>lf", "<cmd>Lspsaga finder<CR>")
		vim.keymap.set("n", "<leader>lo", "<cmd>Lspsaga outline<CR>")
		vim.keymap.set("n", "<leader>la", "<cmd>Lspsaga code_action<CR>")
	end,
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
}
