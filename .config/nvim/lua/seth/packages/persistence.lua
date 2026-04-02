return {
	"folke/persistence.nvim",
	cmd = {
		"PersistenceLoad",
		"PersistenceLoadLast",
		"PersistenceLoadFromFile",
		"PersistenceSelect",
		"PersistenceStop",
	},
	keys = {
		{ "<leader>qs", "<cmd>PersistenceLoad<cr>", desc = "Load session for cwd" },
		{ "<leader>qS", "<cmd>PersistenceSelect<cr>", desc = "Select session" },
		{ "<leader>ql", "<cmd>PersistenceLoadLast<cr>", desc = "Load last session" },
		{ "<leader>qw", "<cmd>lua require('persistence').save()<cr>", desc = "Save session now" },
		{ "<leader>qd", "<cmd>PersistenceStop<cr>", desc = "Stop session save" },
	},
	opts = {},
	config = function(_, opts)
		local persistence = require("persistence")
		persistence.setup(opts)

		local group = vim.api.nvim_create_augroup("seth_persistence_checkpoint", { clear = true })
		local save_interval_ms = 5 * 60 * 1000
		local timer = vim.uv.new_timer()

		local function save_session()
			pcall(persistence.save)
		end

		vim.api.nvim_create_autocmd({ "FocusLost", "VimSuspend", "VimLeavePre" }, {
			group = group,
			callback = save_session,
		})

		timer:start(save_interval_ms, save_interval_ms, vim.schedule_wrap(save_session))

		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = group,
			once = true,
			callback = function()
				timer:stop()
				timer:close()
			end,
		})
	end,
}
