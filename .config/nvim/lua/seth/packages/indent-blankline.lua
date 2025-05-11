return {
	"lukas-reineke/indent-blankline.nvim",
	event = { "BufReadPre", "BufNewFile" },
	main = "ibl",
	opts = {},
	config = function()
		require("ibl").setup({ indent = { tab_char = "▎" } })
	end,
}
