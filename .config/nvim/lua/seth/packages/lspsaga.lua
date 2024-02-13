return {
	"nvimdev/lspsaga.nvim",
	config = function()
		require("lspsaga").setup({})
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
