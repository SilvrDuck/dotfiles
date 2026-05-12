return {
  { "gbprod/nord.nvim", lazy = false, priority = 1000, opts = {} },
  { "folke/tokyonight.nvim", lazy = false, priority = 1000, opts = {} },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        local vault = vim.fn.expand("~/vaults/main")
        local scheme = vim.startswith(vim.fn.getcwd(), vault) and "tokyonight" or "nord"
        vim.cmd.colorscheme(scheme)
      end,
    },
  },
}
