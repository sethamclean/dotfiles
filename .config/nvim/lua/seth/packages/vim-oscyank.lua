return {
  "ojroques/vim-oscyank",
  config = function()
    vim.g.oscyank_term = 'default'
    vim.api.nvim_create_autocmd("TextYankPost", {
      callback = function()
        if vim.v.event.operator == "y" then
          vim.cmd("OSCYankRegister")
        end
      end,
    })
  end,
}

