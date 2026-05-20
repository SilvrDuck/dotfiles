---
name: vim-config
description: >
  This user's exact Neovim setup — LazyVim base, enabled extras, custom
  plugins, keymaps, options, autocmds. Use whenever recommending a key
  sequence or workflow for this user's vim. Triggers: vihelp sessions,
  "how do I X in vim/nvim", "vim golf", "best way to <edit task>",
  references to flash / snacks / yanky / treesitter / dial / noice /
  obsidian / mini.ai in this user's vim.
---

# This user's Neovim

## Source of truth

The summary below decays. **Read the actual config before recommending a
chord** if there's any doubt:

- Plugin manifest + LazyVim extras: `~/.config/nvim/lua/config/lazy.lua`
- Custom plugin overrides: `~/.config/nvim/lua/plugins/*.lua`
- Keymaps: `~/.config/nvim/lua/config/keymaps.lua`
- Options: `~/.config/nvim/lua/config/options.lua`
- Autocmds: `~/.config/nvim/lua/config/autocmds.lua`

## Base distribution

LazyVim. All [LazyVim default keymaps](https://www.lazyvim.org/keymaps) apply
unless overridden below. `<leader>` is `<Space>`.

## LazyVim extras enabled

- `coding.yanky` — yank ring, `<leader>p` history picker, `]p`/`[p` cycle.
- `editor.dial` — `<C-a>`/`<C-x>` smart inc/dec (numbers, dates, booleans,
  hex, semver, …).
- `lang.{json, markdown, python, rust, toml, typescript}` — LSP + treesitter
  + textobjects for these langs.
- `util.dot` — chezmoi-aware filetype handling for `dot_*.tmpl` files.

Treesitter, `mini.ai`, `mini.surround` come from LazyVim core (not extras).
So `af` / `if` (function), `ac` / `ic` (class), `a]` / `i]` (bracket),
`am` / `im` (markdown section), `gsa<motion><char>` (surround add),
`gsd<char>` (delete), `gsr<old><new>` (replace) are all live.

## Custom plugins (`lua/plugins/`)

- `flash.nvim` — `s<2chars>` jump, `S` treesitter jump, rainbow labels,
  integrated into `/` search. The single best motion for any > 3-char target
  visible on screen.
- `snacks.nvim` — explorer (`<leader>e`, dotfiles + ignored shown, dimmed),
  picker (`<leader><space>`), dashboard, scratch.
- `noice.nvim` — cmdline + messages overlay.
- `modes.nvim` — mode-tinted cursorline and line numbers (visual signal,
  no chord).
- `obsidian.nvim` + `render-markdown.nvim` — vault editing.
- `lualine`, `smear-cursor`, `scroll` — UI cosmetic. Lualine sections C
  (breadcrumb / pretty_path) and X (noice / lazy-updates / git diff) form
  one contiguous tinted band in a per-project Peacock color, hashed from
  the cwd repo's root commit SHA — project identity rides on the existing
  statusline content.
- `opencode`, `claude-code`, `pi`, `imp`, `image`, `prose` — domain-specific,
  consult the file before recommending.

## Custom keymaps

- `jk` / `kj` → `<Esc>` in insert, terminal, visual, **and** select modes.
  **Always recommend these over bare `<Esc>`** — the user trained on them.

## Custom options

- `relativenumber=true`, `number=true` — hybrid line numbers. Counts like
  `5j`, `12gg` are trivial — recommend them freely.
- `scrolloff=999` — typewriter scroll, cursor always vertically centered.
  Implications: `H` / `M` / `L` are nearly useless here; `zz` is redundant
  after most motions.
- Python LSP = `ty` (Astral's beta type checker, replaces pyright).
- `clipboard=""` — undoes LazyVim's `unnamedplus`. Yanks reach the system
  clipboard via a `TextYankPost` autocmd; **deletes/changes do not**. So
  `yy` → OS clipboard, but `dd` / `x` / `cw` stay nvim-only. To put a
  delete on the OS clipboard, prefix `"+` (`"+dd`, `"+x`). `"0p` still
  pastes the last yank specifically.

## Custom autocmds (markdown-focused, mostly invisible)

- `TextYankPost` copies the unnamed register into `+` when the operator is
  `y`, so only yanks (not deletes) reach the system clipboard.
- `conceallevel=0` in markdown (so `*emphasis*` and code fences stay literal).
- Spell on for markdown, langs `fr` + `en`, spellfile in `~/vaults/main/.spell/`.
- Hyphenated compounds (`first-save`, `Status-bar`) auto-accepted if all
  parts are dict words.
- YAML frontmatter auto-folded.
- `LineNr` and `WinSeparator` tinted to match mode.
- Vault auto-sync: files saved under `~/vaults/main` trigger a debounced
  background `vault-sync` 2s later, flushed on `:q`.

## When to fetch upstream docs

- **Chord recommendations** → read `~/.config/nvim/lua/plugins/<plugin>.lua`.
  That's the binding source of truth. Don't fetch.
- **Plugin option names / defaults / new features** → context7
  (`resolve-library-id` → `query-docs` with the full question). Fall back
  to WebFetch only if context7 returns nothing.
- **Vim/nvim builtins** (operators, textobjects, ex commands) → trust this
  skill and training; these are stable.

## How to answer well

1. **Read the matching plugin file** if you're recommending a chord that
   isn't standard vim or LazyVim default — option names drift.
2. **Pick the shortest practical sequence**, breaking ties for this user's
   plugins (priority list lives in `~/.config/vihelp/CLAUDE.md`).
3. **Counts are cheap here** — relativenumber is on, so `7dd` / `3}` /
   `12gg` are all natural.
4. **`jk` / `kj`** beat `<Esc>` every time.
5. **Flash beats `f<x>;;;` for any target > 3 chars away** in this setup.
6. **No dark magic** — no obscure `:normal` recipes, no register-juggling
   macros, no `g!` filter tricks.

## Update protocol

This skill mirrors `~/.config/nvim/`. When you edit any file under
`dot_config/nvim/` (or `~/.config/nvim/`), re-read the touched file and
update the relevant section here in the same commit. The `vihelp-skill-watch`
PostToolUse hook (`~/.local/bin/vihelp-skill-watch`, registered in
`~/.claude/settings.json`) will inject a reminder.
