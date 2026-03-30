-- Key cheat sheet
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {},
  config = function()
    local wk = require("which-key")
    wk.add({
      { "<leader>f", group = "Telescope" },
      { "<leader>l", group = "Lspsaga" },
    })
  end,
}
