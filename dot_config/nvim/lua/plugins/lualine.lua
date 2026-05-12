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

      -- Single-letter mode (N/I/V/R/C/T/S). Visual variants all collapse to V
      -- but the accent color already disambiguates line vs block.
      opts.sections.lualine_a = {
        { "mode", fmt = function(s) return s:sub(1, 1) end },
      }

      -- Truncate long branch names (e.g. task-3.4-python-ownership-end-to-end).
      opts.sections.lualine_b = {
        {
          "branch",
          fmt = function(s)
            return #s > 20 and s:sub(1, 19) .. "…" or s
          end,
        },
      }

      -- Replace clock with attached LSP server name(s). Intentionally no
      -- fallback: an empty Z is the signal that no LSP is attached.
      opts.sections.lualine_z = {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return "" end
          local names = {}
          for _, c in ipairs(clients) do
            names[#names + 1] = c.name
          end
          return " " .. table.concat(names, " ")
        end,
      }
    end,
  },
}
