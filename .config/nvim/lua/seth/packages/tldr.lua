return {
	"mrjones2014/tldr.nvim",
	dependencies = { "nvim-telescope/telescope.nvim" },
	config = function()
		require("tldr").setup()
		vim.keymap.set("n", "<leader>fh", require("tldr").pick, { desc = "telescope tldr help." })
	end,
}
