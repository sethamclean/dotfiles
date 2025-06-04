return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- "clangd",
					-- "csharp_ls",
					-- "java_language_server",
					"lua_ls",
					"rust_analyzer",
					"gopls",
					"dockerls",
					"helm_ls",
					"html",
					"kotlin_language_server",
					"jsonls",
					"ts_ls",
					"remark_ls",
					"taplo",
					"terraformls",
					"lemminx",
					"yamlls",
					"ruff",
					"pyrefly",
          "pyright"
				},
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({})
					end,
					-- Custom handler for remark_ls
					["remark_ls"] = function()
						local lspconfig = require("lspconfig")
						local configs = require("lspconfig.configs")
						if not configs.remark_ls then
							configs.remark_ls = {
								default_config = {
									cmd = { "remark-language-server", "--stdio" },
									filetypes = { "markdown" },
									root_dir = lspconfig.util.root_pattern(
										".git",
										".markdownlint.json",
										".markdownlint.yaml",
										".markdownlint.yml",
										".remarkrc",
										"package.json"
									),
									single_file_support = true,
								},
							}
						end
						lspconfig.remark_ls.setup({
							settings = {
								remark = {
									requireConfig = false,
								},
							},
						})
					end,
					-- Custom handler for lua_ls
					["lua_ls"] = function()
						require("lspconfig").lua_ls.setup({
							settings = {
								Lua = {
									runtime = {
										version = "LuaJIT",
									},
									diagnostics = {
										globals = {
											"vim",
											"require",
										},
									},
									workspace = {
										library = vim.api.nvim_get_runtime_file("", true),
									},
									telemetry = {
										enable = false,
									},
									format = {
										enable = true,
										defaultConfig = {
											indent_style = "tab",
											indent_size = "4",
										},
									},
								},
							},
						})
					end,
					-- Custom handler for gopls
					["gopls"] = function()
						require("lspconfig").gopls.setup({
							settings = {
								gopls = {
									buildFlags = { "-tags=integration" },
									gofumpt = true,
								},
							},
						})
					end,
				},
			})
		end,
	},
}
