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
  -- Undotree for local revisioning
  {
    'mbbill/undotree',
    config = function()
      vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle)
    end,
  },
  -- Add telescope fuzzy finder
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', '<C-p>', builtin.git_files, {})
      vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") })
      end)
    end,
  },
  -- Add trouble to add lsp violatoin to gutter and quickfix
  {
    "folke/trouble.nvim",
     dependencies = { "nvim-tree/nvim-web-devicons" },
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
    },
    config = function()
      local cmp = require('cmp')
      cmp.setup({
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'buffer' },
        })
      })
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
