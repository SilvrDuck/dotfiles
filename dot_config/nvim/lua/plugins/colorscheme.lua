local nord = {
  bg0 = "#2e3440", -- nord0
  normal = "#88c0d0", -- nord8 frost blue
  insert = "#a3be8c", -- nord14 green
  visual = "#b48ead", -- nord15 purple
  replace = "#bf616a", -- nord11 red (also operator-pending delete/change)
  command = "#ebcb8b", -- nord13 yellow
}

-- mode() prefix → accent. Operator-pending ("no", "nov", ...) maps to red.
local function accent_for(m)
  local c = m:sub(1, 1)
  if c == "n" then
    if m:sub(1, 2) == "no" then return nord.replace end
    return nord.normal
  end
  if c == "i" or c == "t" then return nord.insert end
  if c == "v" or c == "V" or c == "\22" or c == "s" or c == "S" then return nord.visual end
  if c == "R" then return nord.replace end
  if c == "c" then return nord.command end
  return nord.normal
end

local function paint()
  local m = vim.api.nvim_get_mode().mode
  local accent = accent_for(m)
  vim.api.nvim_set_hl(0, "WinSeparator", { fg = accent, bold = true })
  vim.api.nvim_set_hl(0, "VertSplit", { fg = accent, bold = true })
  -- Lualine "normal" theme covers both normal AND operator-pending — override
  -- bookends so op-pending shows the right accent. Other modes use their own
  -- lualine theme entries from plugins/lualine.lua.
  if m:sub(1, 1) == "n" then
    vim.api.nvim_set_hl(0, "lualine_a_normal", { bg = accent, fg = nord.bg0, bold = true })
    vim.api.nvim_set_hl(0, "lualine_z_normal", { bg = accent, fg = nord.bg0, bold = true })
  end
end

vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme", "VimEnter" }, {
  group = vim.api.nvim_create_augroup("ModeAccents", { clear = true }),
  callback = function() vim.schedule(paint) end,
})

return {
  {
    "gbprod/nord.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      on_highlights = function(hl, _)
        -- nord8 blue, so the normal-mode gutter has the same accent as the
        -- lualine bookends. modes.nvim flashes other colors over this.
        hl.CursorLineNr = { fg = nord.normal, bold = true }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "nord" },
  },
}
