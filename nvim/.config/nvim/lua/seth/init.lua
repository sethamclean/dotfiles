require("seth.remap")
require("seth.packages")

-- Tab settings
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = -1

-- Show line numbers
vim.opt.number = true

-- Draw whitespace and page width
vim.opt.listchars = {
  eol = 'ꜜ',
  space = '·',
  trail = '✚',
  extends = '▶',
  precedes = '◀',
}
vim.opt.list = true
vim.opt.colorcolumn = "80"
