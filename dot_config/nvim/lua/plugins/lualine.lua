-- Custom lualine theme: bookends (sections A + Z) carry the per-mode Nord
-- accent so the statusline matches modes.nvim's gutter tint. Middle sections
-- stay neutral except for a Peacock-style project chip prepended to B,
-- colored by a hash of the cwd's git root commit SHA.
local peacock_palette = {
  "#5e81ac", -- nord10 deep frost
  "#6a8caf", -- periwinkle
  "#4d7ea8", -- ocean
  "#7c89c4", -- cornflower
  "#6e7eb4", -- hyacinth
  "#7a6a8c", -- dusty indigo
  "#9c7ab0", -- amethyst
  "#a87aa3", -- mauve
  "#b08aa8", -- dusty pink
  "#c08fbf", -- orchid
  "#5e8c8a", -- deep teal
  "#4f8a7e", -- jade
  "#5e9e8a", -- sea
  "#8fbcbb", -- nord7 teal-frost
  "#a89378", -- sand
  "#b89b7c", -- ash beige
  "#b3937a", -- wheat
  "#a8826a", -- copper
  "#8c6a5e", -- terracotta
}

local peacock = { name = "", color = nil }

local function peacock_dir()
  -- Resolve a real filesystem dir from the current buffer (handles
  -- `nvim somedir` where process cwd is still the launching shell's cwd).
  -- Strips URI schemes like `oil://`; falls back to cwd for nameless bufs.
  local name = vim.api.nvim_buf_get_name(0):gsub("^%w+://", "")
  if name == "" then return vim.fn.getcwd() end
  return vim.fn.isdirectory(name) == 1 and name or vim.fn.fnamemodify(name, ":h")
end

local function luminance(hex)
  local r = tonumber(hex:sub(2, 3), 16) / 255
  local g = tonumber(hex:sub(4, 5), 16) / 255
  local b = tonumber(hex:sub(6, 7), 16) / 255
  return 0.299 * r + 0.587 * g + 0.114 * b -- ITU-R BT.601 perceived
end

local function peacock_refresh()
  -- Sticky: only update when the resolved dir is inside a git repo.
  -- Scratch/help/other non-repo locations keep the last good value.
  local dir = peacock_dir()
  local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
  if vim.v.shell_error ~= 0 or not root or root == "" then return end
  local key = vim.fn.systemlist({ "git", "-C", root, "rev-list", "--max-parents=0", "HEAD" })[1] or root
  local n = tonumber(vim.fn.sha256(key):sub(1, 8), 16)
  peacock = {
    name = vim.fn.fnamemodify(root, ":t"),
    color = peacock_palette[(n % #peacock_palette) + 1],
  }
end

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

-- Section C and X share a peacock-tinted bg (falls back to nord.bg2 when
-- no git repo is detected). All other sections keep their static colors.
-- Rebuilding the theme — rather than patching highlights post-setup — is
-- the only way to make every component in C/X (and the section-boundary
-- arrows around them) actually inherit the new bg.
local function build_theme()
  local c = peacock.color or nord.bg2
  local cfg = peacock.color
    and (luminance(c) > 0.55 and nord.bg0 or "#eceff4")
    or nord.fg
  local function m(accent)
    return {
      a = { bg = accent, fg = nord.bg0, gui = "bold" },
      b = { bg = nord.bg1, fg = nord.fg },
      c = { bg = c, fg = cfg, gui = peacock.color and "bold" or nil },
      x = { bg = c, fg = cfg },
      y = { bg = nord.bg1, fg = nord.fg },
      z = { bg = accent, fg = nord.bg0, gui = "bold" },
    }
  end
  return {
    normal = m(nord.normal),
    insert = m(nord.insert),
    visual = m(nord.visual),
    replace = m(nord.replace),
    command = m(nord.command),
    inactive = {
      a = { bg = nord.bg1, fg = nord.inactive },
      b = { bg = nord.bg1, fg = nord.inactive },
      c = { bg = c, fg = nord.inactive },
      x = { bg = c, fg = nord.inactive },
      y = { bg = nord.bg1, fg = nord.inactive },
      z = { bg = nord.bg1, fg = nord.inactive },
    },
  }
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      peacock_refresh() -- VimEnter already fired; run once synchronously
      opts.options = opts.options or {}
      opts.options.theme = build_theme()

      -- Rebuild + re-feed lualine on cwd / buffer / colorscheme change.
      local grp = vim.api.nvim_create_augroup("peacock", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged", "ColorScheme" }, {
        group = grp,
        callback = function()
          local prev = peacock.color
          peacock_refresh()
          if peacock.color == prev then return end
          require("lualine").setup({ options = { theme = build_theme() } })
          vim.schedule(function()
            vim.api.nvim_exec_autocmds("User", { pattern = "PeacockRepainted" })
          end)
        end,
      })

      -- Single-letter mode (N/I/V/R/C/T/S). Visual variants all collapse to V
      -- but the accent color already disambiguates line vs block.
      opts.sections.lualine_a = {
        { "mode", fmt = function(s) return s:sub(1, 1) end },
      }

      -- Section B: branch only (project identity lives in the section C
      -- breadcrumb, tinted Peacock below).
      opts.sections.lualine_b = {
        {
          "branch",
          fmt = function(s)
            return #s > 20 and s:sub(1, 19) .. "…" or s
          end,
        },
      }

      -- LazyVim sets per-component color overrides (root_dir = "Special" hue,
      -- noice/lazy = "Statement" hue) that wash out on peacock bg. Override
      -- them with a luminance-aware fg so glyphs stay readable.
      -- Exceptions:
      --   - C/diagnostics: render on nord.bg2 (a grey chip) so severity dots
      --     pop off the peacock band as a visual separator.
      --   - X/diff: leave alone so added/modified/removed keep their hues.
      -- Brute force: after lualine builds its per-component highlights,
      -- enumerate every `lualine_[cx]_*` group and overwrite its bg with
      -- peacock. This catches devicon-derived highlights (filetype icon),
      -- syntax-derived highlights (root_dir, noice cmdline), etc., that
      -- the component-level `color` option can't reach. Transitional
      -- highlights (containing `_to_`) are left alone so section-boundary
      -- arrows still derive correctly from the theme.
      local function force_section_bgs()
        if not peacock.color then return end
        for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
          if name:match("^lualine_[cx]_")
            and not name:match("_to_")
            and not name:match("_diagnostics_")
          then
            local new = vim.deepcopy(hl)
            new.bg = peacock.color
            vim.api.nvim_set_hl(0, name, new)
          end
        end
        -- Invert the LEFT transitional into the diagnostics chip. Lualine's
        -- default makes the chevron grey-on-peacock (chip bg fills outward).
        -- We want peacock-on-grey (prev bg fills INTO the chip).
        -- Identify the right transitionals by bg color (chip's grey) rather
        -- than by highlight name, since the name pattern depends on lualine's
        -- internal component IDs which we don't know upfront.
        local chip_bg_int = tonumber(nord.bg1:sub(2), 16)
        for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
          if name:match("^lualine_transitional_") and hl.bg == chip_bg_int then
            local new = vim.deepcopy(hl)
            new.fg, new.bg = hl.bg, hl.fg
            vim.api.nvim_set_hl(0, name, new)
          end
        end
      end
      -- Diagnostics chip: render with section-style chevrons (left = ,
      -- right = ). Lualine auto-derives the arrow fg/bg from the chip's
      -- own bg vs adjacent components, so the grey chip extends cleanly into
      -- the surrounding section bg on both sides.
      -- Per-component colors set at SETUP time. Lualine derives the
      -- transitional separator highlights (chip ↔ neighbour) from each
      -- adjacent component's bg AT THIS MOMENT — they're frozen afterward,
      -- so post-setup highlight patches won't reach them. Seed them here.
      --
      -- Per lualine highlight.lua:
      --   transitional fg = left_hl.bg
      --   transitional bg = right_hl.bg
      local function peacock_text_color()
        local c = peacock.color or nord.bg2
        return {
          fg = peacock.color
            and (luminance(c) > 0.55 and nord.bg0 or "#eceff4")
            or nord.fg,
          bg = c,
        }
      end
      for _, comp in ipairs(opts.sections.lualine_c or {}) do
        if type(comp) == "table" then
          if comp[1] == "diagnostics" then
            comp.color = function() return { bg = nord.bg1 } end
            -- Both chevrons point right (). Lualine's default derivation
            -- for table-form separators is fg=this_bg, bg=neighbour_bg —
            -- which gives a grey wedge into peacock on BOTH sides. The
            -- LEFT chevron needs to be inverted (peacock-on-grey) — that
            -- swap happens in force_section_bgs() after setup.
            comp.separator = { left = "\u{e0b0}", right = "\u{e0b0}" }
          else
            comp.color = peacock_text_color
          end
        end
      end
      for _, comp in ipairs(opts.sections.lualine_x or {}) do
        if type(comp) == "table" and comp[1] ~= "diff" then
          comp.color = peacock_text_color
        end
      end

      vim.schedule(force_section_bgs)
      -- Re-run after every theme rebuild (cwd change, colorscheme).
      vim.api.nvim_create_autocmd("User", {
        pattern = "PeacockRepainted",
        callback = force_section_bgs,
      })

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
