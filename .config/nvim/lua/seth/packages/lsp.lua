return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
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
}
