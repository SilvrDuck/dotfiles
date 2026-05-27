-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Mirror yanks (and only yanks) to the system clipboard. `clipboard=""` in
-- options.lua keeps d/x/c off the OS clipboard so deletes stay scratch-paste
-- material; this autocmd re-attaches `+` to the y operator alone.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    if vim.v.event.operator == "y" then
      vim.fn.setreg("+", vim.fn.getreg('"'), vim.fn.getregtype('"'))
    end
  end,
})

-- LazyVim sets conceallevel=2 globally; that hides ```fences, *emphasis*, etc.
-- in markdown. Show everything explicitly (Treesitter highlighting still applies).
-- Personal spellfile lives inside the vault so `zg` additions sync across machines.
local spellfile = vim.fn.expand("~/vaults/main/.spell/personal.utf-8.add")
vim.fn.mkdir(vim.fn.fnamemodify(spellfile, ":h"), "p")

-- Hyphenated compounds (Status-bar, first-save) are treated as one token by
-- vim's spell checker and flagged because they're not literal dict entries.
-- Walk the buffer and accept any compound whose parts all pass the dict; real
-- typos inside a compound (spel-checker) still fail. Session-only — no writes
-- to the spellfile, refreshes on reopen. `syntax sync fromstart` is needed
-- because :spellgood! updates the internal word list but does not invalidate
-- already-painted spell highlights on the visible buffer.
local function accept_hyphenated_compounds()
  local seen = {}
  local added = false
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    for compound in line:gmatch("%w+%-[%w%-]+") do
      if not seen[compound] then
        seen[compound] = true
        local ok = true
        for part in compound:gmatch("[^%-]+") do
          local _, attr = unpack(vim.fn.spellbadword(part))
          if attr == "bad" then
            ok = false
            break
          end
        end
        if ok then
          pcall(vim.cmd, "silent! spellgood! " .. compound)
          added = true
        end
      end
    end
  end
  if added then vim.cmd("silent! syntax sync fromstart") end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function(args)
    vim.opt_local.conceallevel = 0
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "fr", "en" }
    vim.opt_local.spellfile = spellfile
    accept_hyphenated_compounds()
    local compound_timer
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = args.buf,
      callback = function()
        if compound_timer then compound_timer:stop() end
        compound_timer = vim.defer_fn(accept_hyphenated_compounds, 500)
      end,
    })
    -- Fold the YAML frontmatter block. Manual foldmethod (rather than reusing
    -- treesitter's foldexpr) because LazyVim's fold setup didn't pick up the
    -- (minus_metadata) addition reliably — manual `:fold` is unconditional.
    -- Tradeoff: treesitter section folds are off for markdown; use `zf` to
    -- create a section fold by hand if needed.
    if vim.fn.getline(1) == "---" then
      local last = vim.fn.line("$")
      for i = 2, math.min(last, 100) do
        if vim.fn.getline(i) == "---" then
          vim.opt_local.foldmethod = "manual"
          vim.cmd(string.format("silent! %d,%dfold", 1, i))
          break
        end
      end
    end
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

