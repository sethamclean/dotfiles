return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	tag = "0.1.8",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		require("telescope").setup({
			extensions = {
				tldr = {
					{
						tldr_command = "tldr",
					},
				},
			},
		})
		local builtin = require("telescope.builtin")
		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local actions = require("telescope.actions")
		local action_state = require("telescope.actions.state")

		local function find_dirs()
			local work_root = vim.env.WORK_ROOT or (vim.env.HOME .. "/ws")
			local search_roots = { work_root, "/root", vim.fn.getcwd() }
			local fd_cmd = {
				"fd",
				"--type",
				"d",
				"-H",
				"-L",
				"--exclude",
				".git",
				"--exclude",
				"node_modules",
				"--exclude",
				".direnv",
				"--exclude",
				".venv",
			}

			for _, root in ipairs(search_roots) do
				table.insert(fd_cmd, "--search-path")
				table.insert(fd_cmd, root)
			end

			pickers
				.new({}, {
					prompt_title = "Directories",
					finder = finders.new_oneshot_job(fd_cmd, {}),
					sorter = conf.generic_sorter({}),
					attach_mappings = function(prompt_bufnr)
						actions.select_default:replace(function()
							local selection = action_state.get_selected_entry()
							local dir = selection and (selection.value or selection[1])
							actions.close(prompt_bufnr)

							if dir and dir ~= "" then
								vim.cmd("lcd " .. vim.fn.fnameescape(dir))
								vim.notify("lcd -> " .. dir, vim.log.levels.INFO)
							end
						end)
						return true
					end,
				})
				:find()
		end

		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "telescope find files." })
		vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "telescope find git files." })
		vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "telescope grep." })
		vim.keymap.set("n", "<leader>fd", find_dirs, { desc = "telescope find directories." })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "telescope find in buffers." })
		vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "telescope find in commands." })
		vim.keymap.set("n", "<leader>ft", builtin.treesitter, { desc = "telescope find in treesitter." })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "telescope find in keymaps." })
		vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "telescope find in marks." })
		vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "telescope find in jumps." })
		vim.keymap.set("n", "<leader>fp", builtin.man_pages, { desc = "telescope find in man pages." })
		vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "telescope find recent(old) files." })
	end,
}
