local function is_command_runnable(command, args)
	if command == nil or command == "" then
		return false
	end

	local cmd = { command }
	if args ~= nil then
		for _, arg in ipairs(args) do
			table.insert(cmd, arg)
		end
	end

	vim.fn.system(cmd)
	return vim.v.shell_error == 0
end

local function resolve_gopls_command()
	-- On Nix systems, Mason-provided ELF binaries can survive updates while their
	-- pinned /nix/store loader path disappears, making them non-runnable. Probe
	-- candidates at runtime and prefer PATH (typically Nix-managed) first.
	local candidates = {
		vim.fn.exepath("gopls"),
		vim.fn.stdpath("data") .. "/mason/bin/gopls",
		"gopls",
	}
	local seen = {}

	for _, candidate in ipairs(candidates) do
		if candidate ~= "" and not seen[candidate] then
			seen[candidate] = true
			if is_command_runnable(candidate, { "version" }) then
				return candidate
			end
		end
	end

	local fallback = vim.fn.exepath("gopls")
	if fallback == "" then
		fallback = "gopls"
	end

	vim.schedule(function()
		vim.notify(
			("No runnable gopls binary found. Checked: %s, %s, %s. Falling back to %s."):format(
				candidates[1] ~= "" and candidates[1] or "(none)",
				candidates[2],
				candidates[3],
				fallback
			),
			vim.log.levels.WARN
		)
	end)

	return fallback
end

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
			local gopls_command = resolve_gopls_command()
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
					"pyright",
				},
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						local original_capabilites = vim.lsp.protocol.make_client_capabilities()
						local capabilities = require("blink.cmp").get_lsp_capabilities(original_capabilites)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
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
							cmd = { gopls_command },
							settings = {
								gopls = {
									buildFlags = { "-tags=integration" },
									gofumpt = true,
								},
							},
						})
					end,
					["yamlls"] = function()
						require("lspconfig").yamlls.setup({
							settings = {
								yaml = {
									format = {
										enable = true,
										singleQuote = true,
										printWidth = 120,
									},
									hover = true,
									completion = true,
									validate = true,
									schemas = {
										["https://raw.githubusercontent.com/helm/charts/master/values.schema.json"] = "/*.yaml",
										["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.{yml,yaml}",
										["https://json.schemastore.org/kustomization.json"] = "kustomization.yaml",
									},
									schemaStore = {
										enable = true,
										url = "https://www.schemastore.org/json",
									},
								},
							},
						})
					end,
				},
			})
		end,
	},
}
