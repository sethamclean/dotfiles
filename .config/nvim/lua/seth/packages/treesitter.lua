return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			-- A list of parser names, or "all" (the five listed parsers should always be installed)
			modules = {}, -- lua_lsp says this is required despite being optional
			ensure_installed = {
				"c",
				"rust",
				"go",
				"python",
				"lua",
				"markdown",
				"markdown_inline",
				"yaml",
				"terraform",
				"json",
				"javascript",
				"typescript",
				"css",
				"toml",
				"xml",
				"html",
			},

			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,

			-- Automatically install missing parsers when entering buffer
			-- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
			auto_install = true,

			-- List of parsers to ignore installing (or "all")
			ignore_install = {},
			highlight = {
				enable = true,
				disable = {},
				additional_vim_regex_highlighting = false,
			},
		})
		vim.opt.foldmethod = "expr"
		vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
		vim.api.nvim_create_autocmd({ "BufEnter", "FileReadPost" }, {
			callback = function()
				vim.cmd("normal zR")
			end,
		})
	end,
}
