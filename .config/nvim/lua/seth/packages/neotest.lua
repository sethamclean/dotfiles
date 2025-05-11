return {
	"nvim-neotest/neotest",
	keys = {
		{ "<leader>tt", function() require("neotest").run.run() end, desc = "Run Nearest" },
		{ "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
		{ "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
		{ "<leader>ts", function() require("neotest").run.stop() end, desc = "Stop" },
		{ "<leader>ta", function() require("neotest").run.attach() end, desc = "Attach" },
		{ "<leader>to", function() require("neotest").output.open() end, desc = "Show Output" },
		{ "<leader>tp", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
		{ "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last" },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-go",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		-- get neotest namespace (api call creates or returns namespace)
		local neotest_ns = vim.api.nvim_create_namespace("neotest")
		vim.diagnostic.config({
			virtual_text = {
				format = function(diagnostic)
					local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
					return message
				end,
			},
		}, neotest_ns)
		require("neotest").setup({
			-- your neotest config here
			adapters = {
				require("neotest-go"),
			},
			log_level = vim.log.levels.DEBUG,
		})
	end,
}
