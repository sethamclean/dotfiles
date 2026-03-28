return {
	"folke/trouble.nvim",
	opts = {},
	event = { "BufReadPre", "BufNewFile" },
	cmd = "Trouble",
	config = function(_, opts)
		require("trouble").setup(opts)

		local group = vim.api.nvim_create_augroup("seth_trouble_auto_diagnostics", { clear = true })
		local is_open = false
		local auto_enabled = true

		local function refresh_trouble_for_buffer(bufnr)
			if not auto_enabled then
				return
			end

			if bufnr == nil or not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			local count = #vim.diagnostic.get(bufnr, {
				severity = {
					min = vim.diagnostic.severity.WARN,
				},
			})

			if count > 0 and not is_open then
				is_open = true
				vim.cmd("Trouble diagnostics open filter.buf=0 focus=false")
			elseif count == 0 and is_open then
				is_open = false
				vim.cmd("Trouble diagnostics close filter.buf=0")
			end
		end

		pcall(vim.api.nvim_del_user_command, "TroubleAutoDiagnosticsToggle")
		vim.api.nvim_create_user_command("TroubleAutoDiagnosticsToggle", function()
			auto_enabled = not auto_enabled

			if not auto_enabled then
				is_open = false
				vim.cmd("Trouble diagnostics close filter.buf=0")
			else
				refresh_trouble_for_buffer(vim.api.nvim_get_current_buf())
			end

			vim.notify(
				("Trouble auto diagnostics %s"):format(auto_enabled and "enabled" or "disabled"),
				vim.log.levels.INFO
			)
		end, { desc = "Toggle Trouble diagnostics auto-open" })

		vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
			group = group,
			callback = function()
				vim.schedule(function()
					refresh_trouble_for_buffer(vim.api.nvim_get_current_buf())
				end)
			end,
		})
	end,
	keys = {
		{
			"<leader>xx",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
		{
			"<leader>xX",
			"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
			desc = "Buffer Diagnostics (Trouble)",
		},
		{
			"<leader>cs",
			"<cmd>Trouble symbols toggle focus=false<cr>",
			desc = "Symbols (Trouble)",
		},
		{
			"<leader>cl",
			"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
			desc = "LSP Definitions / references / ... (Trouble)",
		},
		{
			"<leader>xL",
			"<cmd>Trouble loclist toggle<cr>",
			desc = "Location List (Trouble)",
		},
		{
			"<leader>xQ",
			"<cmd>Trouble qflist toggle<cr>",
			desc = "Quickfix List (Trouble)",
		},
	},
}
