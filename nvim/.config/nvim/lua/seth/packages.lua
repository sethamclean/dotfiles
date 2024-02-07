-- Bootstrap lazy.nvim package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  -- Key cheat sheet
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    config = function()
      local which = require("which-key")
      which.register({
          l = { name = "Lspsaga" },
          }, { prefix = "<leader>" })
      which.register({
          f = { name = "Telescope" },
          }, { prefix = "<leader>" })
    end,
  },
  -- Debugger setup
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "theHamsta/nvim-dap-virtual-text",
      "folke/neodev.nvim",
    },
    config = function()
      require("neodev").setup({
        library = { plugins = { "nvim-dap-ui" }, types = true }})
      require("nvim-dap-virtual-text").setup({})
      require("dapui").setup()
    end,
  },
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
                      { desc='telescope find in git files.'})
      vim.keymap.set('n', '<leader>fs',
                      function()
                        builtin.grep_string({ search = vim.fn.input("Grep > ") })
                      end,
                      { desc='telescope grep.'})
      vim.keymap.set('n', '<leader>fb', builtin.buffers,
                      { desc='telescope find in buffers.'})

    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({

        })
        vim.keymap.set("n", "<leader>lh", '<cmd>Lspsaga hover_doc<CR>')
        vim.keymap.set(
          "n", "<leader>lf", '<cmd>Lspsaga finder<CR>')
        vim.keymap.set("n", "<leader>lo", '<cmd>Lspsaga outline<CR>')
        vim.keymap.set("n", "<leader>la", '<cmd>Lspsaga code_action<CR>')
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons'
    },
  },
  -- Add trouble to add lsp violatoin to gutter and quickfix
  {
    "folke/trouble.nvim",
     dependencies = { "nvim-tree/nvim-web-devicons" },
     opts = {}
  },
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  -- Configure and install LSP servers using these plugins
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    lazy = false,
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup{
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
          "tsserver",
          "marksman",
          "taplo",
          "terraformls",
          "lemminx",
          "yamlls",
        }
      }
      require("mason-lspconfig").setup_handlers {
        -- The first entry (without a key) will be the default handler
        -- and will be called for each installed server that doesn't have
        -- a dedicated handler.
        function (server_name) -- default handler (optional)
            require("lspconfig")[server_name].setup {}
        end,
        ["lua_ls"] = function ()
            require("lspconfig").lua_ls.setup {
            settings = {
              Lua = {
                runtime = {
                  version = 'LuaJIT',
                },
                diagnostics = {
                  globals = {
                    'vim',
                    'require',
                  }
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                },
                telemetry = {
                  enable = false,
                }
              }
            }
          }
        end
      }
    end,
  },
  -- Autocompletion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'neovim/nvim-lspconfig',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      {
        "L3MON4D3/LuaSnip",
        version = "v2.2.*",
        build = "make install_jsregexp"
      },
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup {
        sources = cmp.config.sources({
          { name = "copilot" },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        },{
          { name = 'buffer' },
        }),
        mapping = cmp.mapping.preset.insert {
          ['<CR>'] = cmp.mapping.confirm { select = true },
        },
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
      }
    end,
  },
  -- Git integration
  {
    'lewis6991/gitsigns.nvim',
    dependencies = { 'tpope/vim-fugitive' },
    config = function()
      require('gitsigns').setup()
    end,
  },
  -- Fast AST based syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all" (the five listed parsers should always be installed)
    modules = {}, -- lua_lsp says this is required despite being optional
    ensure_installed = {
      "c",
      "rust",
      "go",
      "python",
      "lua",
      "markdown",
      "markdown_inline",
      "yaml",
      "terraform",
      "json",
      "javascript",
      "typescript",
      "css",
      "toml",
      "xml",
      "html",
    },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- List of parsers to ignore installing (or "all")
    ignore_install = {},
    highlight = {
        enable = true,
          disable = {},
    additional_vim_regex_highlighting = false,
    },
      }
    end
  },
}

-- Kick off package install
require("lazy").setup(plugins)
