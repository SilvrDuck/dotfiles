-- Tint the line number column, cursorline, and signcolumn based on mode.
-- Colors picked from the Nord palette so they line up with the starship
-- vi-mode indicators (insert = green, vimcmd = purple, error = red).
return {
  {
    "mvllow/modes.nvim",
    event = "VeryLazy",
    opts = {
      colors = {
        insert = "#a3be8c", -- nord14, matches starship success/insert
        visual = "#b48ead", -- nord15, matches starship vimcmd
        delete = "#bf616a", -- nord11, matches starship error
        replace = "#d08770", -- nord12
        copy = "#ebcb8b", -- nord13
        format = "#88c0d0", -- nord8
      },
      -- Let smear-cursor.nvim own the cursor — modes.nvim's set_cursor=true
      -- default clashes with it.
      set_cursor = false,
    },
  },
}
