return {
	"rcarriga/nvim-notify",
	config = function()
		require("notify").setup({
			render = "compact",
			stages = "slide",
			timeout = 800,
			max_width = 40,
			max_height = 3,
			top_down = false,
			fps = 30,
		})
		vim.notify = require("notify")
	end,
}
