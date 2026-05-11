-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- LazyVim sets conceallevel=2 globally; that hides ```fences, *emphasis*, etc.
-- in markdown. Show everything explicitly (Treesitter highlighting still applies).
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

-- Tint LineNr column and WinSeparator based on mode, matching plugins/modes.lua.
-- LineNr (non-current lines) blends with the colorscheme's original fg so it
-- stays subdued — CursorLineNr (painted full-saturation by modes.nvim) is the
-- loudest signal. Special buffers (explorer, terminal, dashboards) pin LineNr
-- to a neutral mirror via window-local winhighlight, so the tint stays confined
-- to code windows.
local function blend(fg_hex, bg_int, alpha)
  local r1 = tonumber(fg_hex:sub(2, 3), 16)
  local g1 = tonumber(fg_hex:sub(4, 5), 16)
  local b1 = tonumber(fg_hex:sub(6, 7), 16)
  local r2 = math.floor(bg_int / 65536) % 256
  local g2 = math.floor(bg_int / 256) % 256
  local b2 = bg_int % 256
  return math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5) * 65536
    + math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5) * 256
    + math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
end

local function mode_color(mode)
  local m = mode:sub(1, 1)
  if m == "i" or m == "t" then return "#a3be8c" end -- insert / terminal: nord14
  if m == "v" or m == "V" or m == "\22" or m == "s" or m == "S" or m == "\19" then return "#b48ead" end -- visual / select: nord15
  if m == "R" then return "#d08770" end -- replace: nord12
  if m == "c" then return "#88c0d0" end -- command: nord8
  return nil
end

local tint_groups = { "LineNr", "WinSeparator" }
local tint_defaults = {}
local function tint_snapshot()
  for _, g in ipairs(tint_groups) do
    tint_defaults[g] = vim.api.nvim_get_hl(0, { name = g, link = false })
  end
  -- Stable mirror of the default LineNr so special-buffer winhighlight has
  -- something to pin to that doesn't move with the mode tint.
  vim.api.nvim_set_hl(0, "LineNrNeutral", tint_defaults.LineNr or {})
end
local function tint_apply()
  local color = mode_color(vim.api.nvim_get_mode().mode)
  for _, g in ipairs(tint_groups) do
    local base = tint_defaults[g] or {}
    if color then
      local fg = g == "LineNr" and blend(color, base.fg or 0x4c566a, 0.45) or color
      vim.api.nvim_set_hl(0, g, vim.tbl_extend("force", base, { fg = fg }))
    else
      vim.api.nvim_set_hl(0, g, base)
    end
  end
end

tint_snapshot()
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    tint_snapshot()
    tint_apply()
  end,
})
vim.api.nvim_create_autocmd("ModeChanged", { callback = tint_apply })

vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function(args)
    if vim.bo[args.buf].buftype ~= "" then
      local cur = vim.wo.winhighlight
      if not cur:find("LineNr:LineNrNeutral", 1, true) then
        vim.wo.winhighlight = (cur ~= "" and cur .. "," or "") .. "LineNr:LineNrNeutral"
      end
    end
  end,
})
