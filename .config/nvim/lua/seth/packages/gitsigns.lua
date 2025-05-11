return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "tpope/vim-fugitive" },
	config = function()
		require("gitsigns").setup()
	end,
}
