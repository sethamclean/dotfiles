-- Key cheat sheet
return {
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
}
