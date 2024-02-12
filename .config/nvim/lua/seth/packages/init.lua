return  {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup {}
    end,
  },
  -- Copilot setup
  {
    "zbirenbaum/copilot-cmp",
    dependencies = {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      config = function()
        require("copilot").setup({})
      end,
    },
    config = function ()
      require("copilot_cmp").setup()
    end
  },
  -- Undotree for local revisioning
  {
    'mbbill/undotree',
    config = function()
      vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle,
                      { desc='undotree toggle.'})
    end,
  },
  -- Add telescope fuzzy finder
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files,
                      { desc='telescope find files.'})
      vim.keymap.set('n', '<leader>fg', builtin.git_files,
                      { desc='telescope find git files.'})
      vim.keymap.set('n', '<leader>fs', builtin.live_grep,
                      { desc='telescope grep.'})
      vim.keymap.set('n', '<leader>fb', builtin.buffers,
                      { desc='telescope find in buffers.'})
      vim.keymap.set('n', '<leader>fc', builtin.commands,
                      { desc='telescope find in commands.'})
    end,
  },
  -- Add trouble to add lsp violatoin to gutter and quickfix
  {
    "folke/trouble.nvim",
     dependencies = { "nvim-tree/nvim-web-devicons" },
     opts = {}
  },
  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'tpope/vim-fugitive' },
    config = function()
      require('gitsigns').setup()
    end,
  },
}
