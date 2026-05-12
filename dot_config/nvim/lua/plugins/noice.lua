-- Disable noice's LSP progress toasts. basedpyright/pyright fire many progress
-- events on every keystroke and the "mini" view stacks them. The attached-LSP
-- signal lives in lualine section Z instead.
return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      progress = { enabled = false },
    },
  },
}
