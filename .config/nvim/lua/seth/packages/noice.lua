return {
	"folke/noice.nvim",
	event = "VeryLazy",
	config = function()
		require("noice").setup({
			notify = { enabled = false },
		})
	end,
	opts = {},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}
