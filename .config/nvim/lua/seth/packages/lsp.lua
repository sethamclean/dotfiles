return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"jay-babu/mason-nvim-dap.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		lazy = false,
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {
					-- "clangd",
					-- "csharp_ls",
					-- "java_language_server",
					"lua_ls",
					"rust_analyzer",
					"pylsp",
					"gopls",
					"dockerls",
					"helm_ls",
					"html",
					"kotlin_language_server",
					"jsonls",
					"ts_ls",
					-- "remark_ls",
					"taplo",
					"terraformls",
					"lemminx",
					"yamlls",
				},
			})
			require("mason-lspconfig").setup_handlers({
				-- The first entry (without a key) will be the default handler
				-- and will be called for each installed server that doesn't have
				-- a dedicated handler.
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({})
				end,
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
							},
						},
					})
				end,
				["gopls"] = function()
					require("lspconfig").gopls.setup({
						settings = {
							gopls = {
								gofumpt = true,
							},
						},
					})
				end,
			})
		end,
	},
}
