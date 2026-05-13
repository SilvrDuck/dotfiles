return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    anti_conceal = {
      enabled = true,
      disabled_modes = { "n", "c", "t", "v", "V" },
    },
    render_modes = { "n", "c", "t", "i", "v", "V" },
    win_options = {
      concealcursor = { rendered = "nvc" },
    },
  },
}
