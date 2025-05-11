return {
	"folke/trouble.nvim",
	cmd = { "TroubleToggle", "Trouble" },
	keys = {
		{ "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
	},
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {},
}
