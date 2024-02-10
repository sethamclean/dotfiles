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
    -- Configure and install LSP servers and debuggers using these plugins
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
      require("mason-nvim-dap").setup({
      ensure_installed = {'delve', 'python', 'codelldb'},
      automatic_installation = true,
      handlers = {
          function(config)
            -- all sources with no handler get passed here

            -- Keep original functionality
            require('mason-nvim-dap').default_setup(config)
          end,
          python = function(config)
              config.adapters = {
                type = "executable",
                command = "/usr/bin/env",
                args = {
                  "python3",
                  "-m",
                  "debugpy.adapter",
                },
              }
              require('mason-nvim-dap').default_setup(config) -- don't forget this!
          end,
          delve = function(config)
            config.adapters = {
              type = "server",
              port = "${port}",
              executable = {
                command = vim.fn.stdpath("data") .. '/mason/bin/dlv',
                args = { "dap", "-l", "127.0.0.1:${port}" },
              },
            }
              require('mason-nvim-dap').default_setup(config) -- don't forget this!
          end,
        },
      })
      local dap = require("dap")
      dap.adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. '/mason/bin/dlv',
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }
       dap.configurations.rust = {
         {
          name = "LLDB: Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            local output = vim.fn.systemlist("cargo build -q --message-format=json 2>1")
            for _, l in ipairs(output) do
              local json = vim.json.decode(l)
              if json == nil then
                error("error parsing json")
              end
              if json.success == false then
                return error("error building package")
              end
              if json.executable ~= nil then
                return json.executable
              end
            end
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }
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
