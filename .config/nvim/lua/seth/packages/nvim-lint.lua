return {
	"mfussenegger/nvim-lint",
	config = function()
		require("lint").linters_by_ft = {
			python = { "mypy", "pylint", "flake8" },
			sh = { "shellcheck" },
			go = { "golangcilint" },
			terraform = { "terraform_validate" },
			tf = { "terraform_validate" },
		}
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
