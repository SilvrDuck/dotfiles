return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    table.insert(opts.sections.lualine_x, 1, function()
      return require("imp.statusline").get()
    end)
  end,
}
