return {
	"dracula/vim",
	lazy = false,
	priority = 1000,
	config = function()
		vim.cmd.colorscheme("dracula")
		vim.api.nvim_set_hl(0, "Normal", { fg = "#ffffff", bg = "#101010" })
		vim.api.nvim_set_hl(0, "SignColumn", { fg = "#ffffff", bg = "#101010" })
	end,
}
