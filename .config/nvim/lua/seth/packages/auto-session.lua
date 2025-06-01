return {
	"rmagatti/auto-session",
	config = function()
		require("auto-session").setup({
			auto_session_enable_last_session = false, -- Only restore if in a project dir
			auto_session_root_dir = vim.fn.stdpath("data") .. "/sessions/",
			auto_save_enabled = true,
			auto_restore_enabled = true,
		})

		-- Improved VimLeavePre autocmd for reliable session saving
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				local has_avante = false
				-- Defensive: check all windows for Avante filetype
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local ok, ft = pcall(vim.api.nvim_buf_get_option, buf, "filetype")
					if ok and ft == "Avante" then
						has_avante = true
						vim.notify("Skipping session save: Avante panel open", vim.log.levels.INFO)
						break
					end
				end
				if not has_avante then
					local ok, err = pcall(function()
						require("auto-session").SaveSession()
					end)
					if not ok then
						vim.notify("Session save failed: " .. tostring(err), vim.log.levels.ERROR)
					else
						vim.notify("Session saved on exit", vim.log.levels.INFO)
					end
				end
			end,
			desc = "Auto-save session only on close, skipping if Avante panel is open",
		})
	end,
}
