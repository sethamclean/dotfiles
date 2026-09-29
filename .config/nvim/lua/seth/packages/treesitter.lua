local parsers = {
	"c",
	"rust",
	"go",
	"python",
	"lua",
	"markdown",
	"markdown_inline",
	"yaml",
	"terraform",
	"hcl",
	"json",
	"javascript",
	"typescript",
	"css",
	"toml",
	"xml",
	"html",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = function()
		if vim.fn.executable("tree-sitter") == 1 then
			vim.cmd("TSUpdate")
		end
	end,
	config = function()
		local has_tree_sitter_cli = vim.fn.executable("tree-sitter") == 1
		local ok, nvim_treesitter = pcall(require, "nvim-treesitter")
		if not ok then
			return
		end

		nvim_treesitter.setup({})

		if has_tree_sitter_cli then
			nvim_treesitter.install(parsers)
		else
			vim.schedule(function()
				vim.notify(
					"nvim-treesitter main requires the tree-sitter CLI for parser installation. Existing parsers will still load if present.",
					vim.log.levels.WARN
				)
			end)
		end

		local treesitter_group = vim.api.nvim_create_augroup("seth-treesitter", { clear = true })

		vim.api.nvim_create_autocmd("FileType", {
			group = treesitter_group,
			callback = function(args)
				pcall(vim.treesitter.start, args.buf)
				vim.bo[args.buf].syntax = "off"
				vim.opt_local.foldmethod = "expr"
				vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
			end,
		})

		vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "FileReadPost" }, {
			group = treesitter_group,
			callback = function()
				vim.cmd("normal! zR")
			end,
		})
	end,
}
