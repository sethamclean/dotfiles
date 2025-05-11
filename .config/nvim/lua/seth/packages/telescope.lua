return {
	"nvim-telescope/telescope.nvim",
	cmd = "Telescope",
	keys = {
		{ "<leader>f", desc = "Telescope" },
	},
	tag = "0.1.5",
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
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "telescope find files." })
		vim.keymap.set("n", "<leader>fg", builtin.git_files, { desc = "telescope find git files." })
		vim.keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "telescope grep." })
		vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "telescope find in buffers." })
		vim.keymap.set("n", "<leader>fc", builtin.commands, { desc = "telescope find in commands." })
		vim.keymap.set("n", "<leader>ft", builtin.treesitter, { desc = "telescope find in treesitter." })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "telescope find in keymaps." })
		vim.keymap.set("n", "<leader>fm", builtin.marks, { desc = "telescope find in marks." })
		vim.keymap.set("n", "<leader>fj", builtin.jumplist, { desc = "telescope find in jumps." })
		vim.keymap.set("n", "<leader>fp", builtin.man_pages, { desc = "telescope find in man pages." })
	end,
}
