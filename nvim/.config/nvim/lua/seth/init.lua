require("seth.remap")
require("seth.packages")

-- Tab settings
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = -1

-- Show line numbers
vim.opt.number = true

-- File persistence
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- search settings
vim.opt.ignorecase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "auto:1-4"

vim.opt.updatecount = 50

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
