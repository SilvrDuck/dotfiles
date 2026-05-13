return {
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        animate = {
          duration = { step = 10, total = 150 },
          easing = "linear",
        },
        filter = function(buf)
          return vim.g.snacks_scroll ~= false
            and vim.b[buf].snacks_scroll ~= false
            and vim.bo[buf].buftype ~= "terminal"
            and not vim.fn.mode():find("[vVsS\22\19]")
        end,
      },
    },
  },
}
