return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("gruvbox")
    vim.api.nvim_set_hl(0, 'Normal', { fg = "#ffffff", bg = "#101010" })
    vim.api.nvim_set_hl(0, 'SignColumn', { fg = "#ffffff", bg = "#101010" })
  end,
}
