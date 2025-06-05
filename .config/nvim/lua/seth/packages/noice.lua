return {
	"folke/noice.nvim",
	event = "VeryLazy",
	config = function()
		require("noice").setup({
			routes = {
				{
					view = "mini",
					filter = {
						event = "notify",
						kind = "info",
					},
				},
				{
					view = "mini",
					filter = {
						event = "notify",
						kind = "warn",
					},
				},
			},
		})
	end,
	opts = {},
	dependencies = {
		"MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
}
