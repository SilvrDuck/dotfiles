-- Custom lualine theme: bookends (sections A + Z) carry the per-mode Nord
-- accent so the statusline matches modes.nvim's gutter tint. Middle sections
-- stay neutral.
local nord = {
  bg0 = "#2e3440", -- nord0 (dark bg, used as fg on accented bookends)
  bg1 = "#3b4252", -- nord1 (section B/Y)
  bg2 = "#434c5e", -- nord2 (section C/X)
  fg = "#d8dee9", -- nord4
  inactive = "#4c566a", -- nord3
  normal = "#88c0d0", -- nord8 frost blue
  insert = "#a3be8c", -- nord14 green
  visual = "#b48ead", -- nord15 purple
  replace = "#bf616a", -- nord11 red
  command = "#ebcb8b", -- nord13 yellow
}

local function mode(accent)
  return {
    a = { bg = accent, fg = nord.bg0, gui = "bold" },
    b = { bg = nord.bg1, fg = nord.fg },
    c = { bg = nord.bg2, fg = nord.fg },
    x = { bg = nord.bg2, fg = nord.fg },
    y = { bg = nord.bg1, fg = nord.fg },
    z = { bg = accent, fg = nord.bg0, gui = "bold" },
  }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = {
        normal = mode(nord.normal),
        insert = mode(nord.insert),
        visual = mode(nord.visual),
        replace = mode(nord.replace),
        command = mode(nord.command),
        inactive = {
          a = { bg = nord.bg1, fg = nord.inactive },
          b = { bg = nord.bg1, fg = nord.inactive },
          c = { bg = nord.bg2, fg = nord.inactive },
          x = { bg = nord.bg2, fg = nord.inactive },
          y = { bg = nord.bg1, fg = nord.inactive },
          z = { bg = nord.bg1, fg = nord.inactive },
        },
      }
    end,
  },
}
